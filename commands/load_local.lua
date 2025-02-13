
function blockexchange.load_local(playername, pos1, schemaname)
    local ctx = {
		type = "download_local",
		schemaname = schemaname,
		current_part = 0,
		progress_percent = 0
	}

	local promise = Promise.async(function(await)

        local filename = blockexchange.get_local_filename(schemaname)
        ctx.zipfile = io.open(filename, "rb")
        if not ctx.zipfile then
            error("file not found: " .. filename, 0)
        end
        local z, err_msg = mtzip.unzip(ctx.zipfile)
        if err_msg then
            error("unzip error: " .. err_msg, 0)
        end
        ctx.zip = z

        local schema_str
        schema_str, err_msg = ctx.zip:get("schema.json", true)
        if err_msg then
            error("schema.json error: " .. err_msg, 0)
        end
        local schema = minetest.parse_json(schema_str)

        local pos2 = vector.add(pos1, blockexchange.get_schema_size(schema))
        pos2 = vector.subtract(pos2, 1)
        blockexchange.set_pos(2, playername, pos2)
        ctx.total_parts = blockexchange.count_schemaparts(pos1, pos2)

		for current_pos in blockexchange.iterator(ctx.origin, ctx.pos1, ctx.pos2) do
			local relative_pos = vector.subtract(current_pos, ctx.pos1)
			local entry_filename = "schemapart_" .. relative_pos.x .. "_" .. relative_pos.y .. "_" .. relative_pos.z .. ".json"
			local entry = ctx.zip:get_entry(entry_filename)
			if entry then
				-- non-air part
                local schemapart_str
				schemapart_str, err_msg = ctx.zip:get(entry_filename, true)
				if err_msg then
					error("schemapart error: " .. err_msg, 0)
				end
				local schemapart = minetest.parse_json(schemapart_str)

				-- increment stats
				ctx.current_part = ctx.current_part + 1
				ctx.progress_percent = math.floor(ctx.current_part / ctx.total_parts * 100 * 10) / 10

				blockexchange.place_schemapart(schemapart, pos1)
				minetest.log("action", "[blockexchange] Extraction of part " .. minetest.pos_to_string(current_pos) .. " completed")

				ctx.last_schemapart = schemapart
			end

			if ctx.cancel then
				error("canceled", 0)
			end
			await(Promise.after(blockexchange.min_delay))
		end

		return {
            total_parts = ctx.total_parts
        }
	end)

    blockexchange.set_job_context(playername, ctx, promise)
    return promise
end


Promise.register_chatcommand("bx_load_local", {
    params = "<schemaname>",
    description = "loads a local schema to the selected pos1",
    privs = {blockexchange = true},
    func = function(name, schemaname)
        -- force-enable the hud
        blockexchange.set_player_hud(name, true)

        if blockexchange.get_job_context(name) then
            return true, "There is a job already running"
        end

        if not schemaname or schemaname == "" then
            return false, "Usage: /bx_load <username> <schemaname>"
        end

        local pos1 = blockexchange.get_pos(1, name)

        if not pos1 then return false, "you need to set /bx_pos1 first!" end

        return blockexchange.load_local(name, pos1, schemaname):next(function(result)
            return "Local extraction complete with " .. result.total_parts .. " parts"
        end)
    end
})

