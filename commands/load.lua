
--- load a schematic asynchronously
-- @param playername the playername to use in messages
-- @param pos1 lower position to load
-- @param username the username/owner of the schema
-- @param schemaname the name of the schema
-- @param[opt] from_mtime start with block mtime
-- @return a promise that resolves if the operation is complete
function blockexchange.load(playername, pos1, username, schemaname, from_mtime)
	local ctx = {
		type = "download",
		retries = 0,
		playername = playername,
		username = username,
		schemaname = schemaname,
		current_part = 0,
		progress_percent = 0
	}

	local promise = Promise.async(function(await)
		local schema, err = await(blockexchange.api.get_schema_by_name(username, schemaname, true))
		if err then
			error("error fetching schema: " .. err, 0)
		elseif not schema then
			error("schema not found: '" .. username .. "/" .. schemaname .. "'", 0)
		end
		local pos2 = vector.add(pos1, blockexchange.get_schema_size(schema))

		-- current mtime, if set
		local mtime = from_mtime or 0

		local total_parts
		total_parts, err = await(blockexchange.api.count_next_schemapart_by_mtime(schema.uid, mtime))
		if err then
			error("error fetching total parts: " .. err, 0)
		end

		-- current schemapart
		local schemapart

		while true do
			if mtime > 0 then
				-- incremental download by mtime
				schemapart, err = await(blockexchange.api.get_next_schemapart_by_mtime(schema.uid,  mtime))
				if err then
					-- retry later
					ctx.retries = ctx.retries + 1
					await(Promise.after(5))
				elseif schemapart then
					-- success
					ctx.current_part = ctx.current_part + 1
					mtime = schemapart.mtime
					blockexchange.place_schemapart(schemapart, pos1)
				else
					-- no more schemaparts
					break
				end
			else
				-- full download
				if not schemapart then
					-- first part
					schemapart, err = await(blockexchange.api.get_first_schemapart(schema.uid))
					if err then
						-- retry later
						ctx.retries = ctx.retries + 1
						await(Promise.after(5))
					elseif not schemapart then
						-- empty schema
						break
					else
						ctx.current_part = ctx.current_part + 1
						blockexchange.place_schemapart(schemapart, pos1)
					end
				else
					-- other parts
					local pos = {
						x = schemapart.offset_x,
						y = schemapart.offset_y,
						z = schemapart.offset_z
					}
					schemapart, err = await(blockexchange.api.get_next_schemapart(schema.uid, pos))
					if err then
						ctx.retries = ctx.retries + 1
						await(Promise.after(5))
					elseif not schemapart then
						-- done
						break
					else
						ctx.current_part = ctx.current_part + 1
						blockexchange.place_schemapart(schemapart, pos1)
					end
				end
			end

			-- compute stats
			ctx.progress_percent = math.floor(ctx.current_part / total_parts * 100 * 10) / 10

			await(Promise.after(blockexchange.min_delay))

			if ctx.cancel then
				error("canceled", 0)
			end
		end

		blockexchange.register_area(pos1, pos2, playername, username, schema)

		return {
			total_parts = total_parts,
			last_schemapart = schemapart,
			schema = schema
		}
	end)

	blockexchange.set_job_context(playername, ctx, promise)
	return promise
end



Promise.register_chatcommand("bx_load", {
    params = "<username> <schemaname>",
    description = "Downloads a schema from the blockexchange to the selected pos1",
    privs = {blockexchange = true},
    func = function(name, param)

        if blockexchange.get_job_context(name) then
            return true, "There is a job already running"
        end

        local _, _, username, schemaname = string.find(param, "^([^%s]+)%s+(.*)$")

        if not username or not schemaname then
            return false, "Usage: /bx_load <username> <schemaname>"
        end

        local pos1 = blockexchange.get_pos(1, name)

        if not pos1 then return false, "you need to set /bx_pos1 first!" end

        -- force-enable player-hud
        blockexchange.set_player_hud(name, true)

        return blockexchange.load(name, pos1, username, schemaname):next(function(result)
            return "Download complete with " .. result.schema.total_parts .. " parts"
        end)
    end
})

minetest.register_chatcommand("bx_load_update", {
    params = "[area_id?]",
    description = "downloads changes",
    privs = {blockexchange = true},
    func = function(name, area_id)
        -- force-enable the hud
        blockexchange.set_player_hud(name, true)

        local area, err_msg = blockexchange.select_player_area(name, area_id)
        if err_msg then
            return false, err_msg
        end

		return blockexchange.load(name, area.pos1, area.username, area.name, area.mtime):next(function(stat)
			if stat.last_schemapart then
				-- some parts have been updated
				-- save last mtime
				area.mtime = stat.last_schemapart.mtime
				blockexchange.save_areas()
				return "Load-update complete with " .. stat.total_parts .. " parts"
			else
				-- nothing has been updated
				return "No updates available"
			end
		end)
    end
})