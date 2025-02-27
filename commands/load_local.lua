
function blockexchange.load_local(playername, origin, schemaname)
    local job = {
        hud_icon = "blockexchange_download.png",
		hud_text = "Local download '" .. schemaname .. "' starting"
	}

    local current_part = 0
    local zip

    job.promise = Promise.async(function(await)

        local err
        local filename = blockexchange.get_local_filename(schemaname)
        local zipfile = io.open(filename, "rb")
        if not zipfile then
            error("file not found: " .. filename, 0)
        end
        zip, err = mtzip.unzip(zipfile)
        if err then
            error("unzip error: " .. err, 0)
        end

        local schema_str
        schema_str, err = zip:get("schema.json", true)
        if err then
            error("schema.json error: " .. err, 0)
        end
        local schema = minetest.parse_json(schema_str)

        local pos2 = vector.add(origin, blockexchange.get_schema_size(schema))
        pos2 = vector.subtract(pos2, 1)
        blockexchange.set_pos(2, playername, pos2)
        local total_parts = blockexchange.count_schemaparts(origin, pos2)

		for current_pos in blockexchange.iterator(origin, origin, pos2) do
            -- TODO: maybe iterate over files instead of map-parts
			local relative_pos = vector.subtract(current_pos, origin)
			local entry_filename = "schemapart_" .. relative_pos.x .. "_" .. relative_pos.y .. "_" .. relative_pos.z .. ".json"
			local entry = zip:get_entry(entry_filename)
			if entry then
				-- non-air part
                local schemapart_str
				schemapart_str, err = zip:get(entry_filename, true)
				if err then
					error("schemapart error: " .. err, 0)
				end
				local schemapart = minetest.parse_json(schemapart_str)

				-- increment stats
				current_part = current_part + 1
				local progress_percent = math.floor(current_part / total_parts * 100 * 10) / 10
                job.hud_text = "Local download '" .. schemaname ..
				    "', progress: " .. progress_percent .. " %"

				blockexchange.place_schemapart(schemapart, origin)
				minetest.log("action", "[blockexchange] Extraction of part " .. minetest.pos_to_string(current_pos) .. " completed")
			end

			if job.cancel then
				error("canceled", 0)
			end
			await(Promise.after(blockexchange.min_delay))
		end

		return {
            total_parts = total_parts
        }
	end)

    blockexchange.add_job(playername, job)
    return job.promise
end


Promise.register_chatcommand("bx_load_local", {
    params = "<schemaname>",
    description = "loads a local schema to the selected pos1",
    privs = {blockexchange = true},
    func = function(name, schemaname)
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

