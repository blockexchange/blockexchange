-- update a region
function blockexchange.save_update(playername, origin, pos1, pos2, schema_uid, options)
	pos1, pos2 = blockexchange.sort_pos(pos1, pos2)
	options = options or {}
	options.progress_callback = options.progress_callback or function() end

	local player_settings = blockexchange.get_player_settings(playername)
	local token = player_settings.token
	if not token then
		return Promise.reject("not logged in")
	end

	local job = {
		hud_icon = "blockexchange_upload.png",
		hud_text = "Saving changes"
	}

	local mod_names = {}

	job.promise = Promise.async(function(await)
		for current_pos, relative_pos, progress in blockexchange.iterator(origin, pos1, pos2) do
			local current_pos2 = vector.add(current_pos, 15)
			current_pos2.x = math.min(current_pos2.x, pos2.x)
			current_pos2.y = math.min(current_pos2.y, pos2.y)
			current_pos2.z = math.min(current_pos2.z, pos2.z)

			local progress_percent = math.floor(progress * 100 * 10) / 10
			options.progress_callback(progress_percent)
			job.hud_text = "Saving changes, progress: " .. progress_percent .. " %"

			local data, node_count = blockexchange.serialize_part(current_pos, current_pos2)
			blockexchange.collect_node_count(node_count, mod_names)

			-- package data properly over the wire
			local schemapart = await(blockexchange.create_schemapart(data, relative_pos, schema_uid))

			-- upload part online
			local _, err = await(blockexchange.api.create_schemapart(player_settings.token, schemapart))
			if err then
				error("create error at " .. minetest.pos_to_string(relative_pos) .. ": " .. err, 0)
			end

			-- create an array with mod names
			local mod_names_list = {}
			for k in pairs(mod_names) do
				table.insert(mod_names_list, k)
			end

			_, err = await(blockexchange.api.create_schemamods(player_settings.token, schema_uid, mod_names_list))
			if err then
				error("error creating mod-list: " .. err, 0)
			end

			if job.cancel then
				error("canceled", 0)
			end

			await(Promise.after(blockexchange.min_delay))
		end

		local area = blockexchange.get_area(pos1)
		if area then
			-- update area mtime
			local schema, err = await(blockexchange.api.get_schema_by_uid(schema_uid))
			if err then
				error("schema get error: " .. err, 0)
			end
			area.mtime = schema.mtime
			blockexchange.save_areas()
		end
	end)

	blockexchange.add_job(playername, job)
	return job.promise
end

-- update a region of a schema
function blockexchange.save_update_area(playername, pos1, pos2, save_pos1, save_pos2, schema_uid)
	-- clip to schema area
	save_pos1, save_pos2 = blockexchange.clip_area(pos1, pos2, save_pos1, save_pos2)

	-- get offset within schema area
	local offset_pos1 = blockexchange.get_schemapart_offset(pos1, save_pos1)
	local _, offset_pos2 = blockexchange.get_schemapart_offset(pos1, save_pos2)

	-- get absolute coords
	local abs_pos1 = vector.add(pos1, offset_pos1)
	local abs_pos2 = vector.add(pos1, offset_pos2)

	abs_pos1, abs_pos2 = blockexchange.clip_area(pos1, pos2, abs_pos1, abs_pos2)
	abs_pos1, abs_pos2 = blockexchange.sort_pos(abs_pos1, abs_pos2)

	return blockexchange.save_update(playername, pos1, abs_pos1, abs_pos2, schema_uid)
end

-- update a region on a single position
function blockexchange.save_update_pos(playername, pos1, pos2, pos, schema_uid)
	local offset_pos1, offset_pos2 = blockexchange.get_schemapart_offset(pos1, pos)
	local abs_pos1 = vector.add(pos1, offset_pos1)
	local abs_pos2 = vector.add(pos1, offset_pos2)

	abs_pos1, abs_pos2 = blockexchange.clip_area(pos1, pos2, abs_pos1, abs_pos2)
	return blockexchange.save_update(playername, pos1, abs_pos1, abs_pos2, schema_uid)
end

Promise.register_chatcommand("bx_save_update", {
    params = "[area_id?]",
    description = "uploads selected changes or the whole area",
    func = function(name, area_id)
        local area, err_msg = blockexchange.select_player_area(name, area_id)
        if err_msg then
            return true, err_msg
        end

        local claims = blockexchange.get_claims(name)
        if not claims then
            return true, "Not logged in"
        end

        if claims.username ~= area.username then
            return true, "You are not authorized to update that schema"
        end

        local pos1 = blockexchange.get_pos(1, name)
        local pos2 = blockexchange.get_pos(2, name)

        if not pos1 or not pos2 then
            -- upload everything
            pos1 = area.pos1
            pos2 = area.pos2
        end

        -- partial update with the marked area
        pos1, pos2 = blockexchange.sort_pos(pos1, pos2)

		return Promise.async(function(await)
			local _, err = await(
				blockexchange.save_update_area(name, area.pos1, area.pos2, pos1, pos2, area.schema_uid)
			)
			if err then
				error("save error: " .. err, 0)
			end

			local schema
			schema, err = await(blockexchange.api.get_schema_by_uid(area.schema_uid))
			if err then
				error("fetch new schema error: " .. err, 0)
			elseif not schema then
				error("schema not found: " .. area.schema_uid, 0)
			end

			-- update mtime
			area.mtime = schema.mtime
            blockexchange.save_areas()
		end)
    end
})