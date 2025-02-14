local has_monitoring = minetest.get_modpath("monitoring")

local uploaded_blocks

if has_monitoring then
	uploaded_blocks = monitoring.counter(
		"blockexchange_uploaded_blocks",
		"number of successfully uploaded mapblocks"
	)
end

function blockexchange.save(playername, pos1, pos2, schemaname)
	pos1, pos2 = blockexchange.sort_pos(pos1, pos2)

	local token = blockexchange.get_token(playername)
	local claims = blockexchange.get_claims(playername)
	local license = blockexchange.get_license(playername)

	if not token or not claims then
		return Promise.rejected("not logged in")
	end

	local ctx = {
		hud_icon = "blockexchange_upload.png",
		hud_text = "Saving '" .. claims.username .. "/" .. schemaname .. "'"
	}

	local schema = {
		size_x = pos2.x - pos1.x + 1,
		size_y = pos2.y - pos1.y + 1,
		size_z = pos2.z - pos1.z + 1,
		description = "",
		license = license,
		name = schemaname
	}

	local total_size = 0
	local retries = 0
	local mod_names = {}
	local total_parts = 0

	local promise = Promise.async(function(await)
		local _, err
		schema, err = await(blockexchange.api.create_schema(token, schema))
		if err then
			error("error creating schema: " .. err, 0)
		end

		for current_pos, relative_pos, progress in blockexchange.iterator(pos1, pos1, pos2) do
			local current_pos2 = vector.add(current_pos, 15)
			current_pos2.x = math.min(current_pos2.x, pos2.x)
			current_pos2.y = math.min(current_pos2.y, pos2.y)
			current_pos2.z = math.min(current_pos2.z, pos2.z)

			local progress_percent = math.floor(progress * 100 * 10) / 10
			ctx.hud_text = "Saving '" .. claims.username .. "/" .. schemaname ..
				"', progress: " .. progress_percent .. " %"

			local data, node_count, air_only = blockexchange.serialize_part(current_pos, current_pos2)
			blockexchange.collect_node_count(node_count, mod_names)

			if not air_only then
				local schemapart = {
					schema_uid = schema.uid,
					offset_x = relative_pos.x,
					offset_y = relative_pos.y,
					offset_z = relative_pos.z,
					data = minetest.encode_base64(blockexchange.compress_data(data)),
					metadata = minetest.encode_base64(blockexchange.compress_metadata(data))
				}

				total_size = total_size + #schemapart.data + #schemapart.metadata
				total_parts = total_parts + 1

				while true do
					-- retry loop
					_, err = await(blockexchange.api.create_schemapart(token, schemapart))
					if err then
						if retries > 12 then
							error("create schemapart failed after " .. retries .. " retries: " .. err, 0)
						end
						-- retry again later
						await(Promise.after(5))
						retries = retries + 1
					else
						-- saved successfully
						if has_monitoring then
							uploaded_blocks.inc(1)
						end
						break
					end
				end

				-- TODO
			end

			if ctx.cancel then
				error("canceled", 0)
			end

			await(Promise.after(blockexchange.min_delay))
		end

		-- create an array with mod names
		local mod_names_list = {}
		for k in pairs(mod_names) do
			table.insert(mod_names_list, k)
		end

		_, err = await(blockexchange.api.create_schemamods(token, schema.uid, mod_names_list))
		if err then
			error("error creating mod-list: " .. err, 0)
		end

		_, err = await(blockexchange.api.update_schema_stats(token, schema.uid))
		if err then
			error("error updating stats: " .. err, 0)
		end

		-- get updated schema
		schema, err = await(blockexchange.api.get_schema_by_name(claims.username, schemaname))
		if err then
			error("error fetching updated schema: " .. err, 0)
		elseif not schema then
			error("saved schema not found: " .. claims.username .. "/" .. schemaname, 0)
		end

		-- register area
		blockexchange.register_area(pos1, pos2, playername, claims.username, schema)

		return {
			total_parts = total_parts,
			total_size = total_size,
			schema = schema
		}
	end)

	blockexchange.set_job_context(playername, ctx, promise)
	return promise
end


Promise.register_chatcommand("bx_save", {
	params = "<name>",
	description = "Uploads the selected region to the blockexchange server",
	func = function(name, schemaname)
		if blockexchange.get_job_context(name) then
			return true, "There is a job already running"
		end

		local has_protected_upload_priv = minetest.check_player_privs(name, { blockexchange_protected_upload = true })
		local has_blockexchange_priv = minetest.check_player_privs(name, { blockexchange = true })
		local has_protection_bypass_priv = minetest.check_player_privs(name, { protection_bypass = true })

		if not has_blockexchange_priv and not has_protected_upload_priv then
			return true, "Required privs: 'blockexchange' or 'blockexchange_protected_upload'"
		end

		if not schemaname then
			return true, "Usage: /bx_save <schemaname>"
		end

		if not blockexchange.validate_name(schemaname) then
			return true, "schema name can only contain letters, numbers and a handful of special chars: - _ ."
		end

		local token = blockexchange.get_token(name)
		if not token then
			-- TODO check validity
			return true, "Please login first to upload a schematic"
		end

		local pos1 = blockexchange.get_pos(1, name)
		local pos2 = blockexchange.get_pos(2, name)

		if not pos1 or not pos2 then
			return true, "you need to set /bx_pos1 and /bx_pos2 first!"
		end

		if not blockexchange.check_size(pos1, pos2) then
			return true, "axis size limit of " .. blockexchange.max_size .. " nodes exceeded"
		end

		-- force-enable player-hud
		blockexchange.set_player_hud(name, true)

		return Promise.async(function(await)
			local err, result
			if not has_blockexchange_priv and has_protected_upload_priv and not has_protection_bypass_priv then
				-- check protection first
				result, err = await(blockexchange.protectioncheck(name, pos1, pos2))
				if err then
					error("protection check error: " .. err, 0)
				elseif not result.success then
					local msg = "protection check failed between pos " .. minetest.pos_to_string(result.pos1) ..
						" and " .. minetest.pos_to_string(result.pos2)
					error(msg, 0)
				end
			end

			result, err = await(blockexchange.save(name, pos1, pos2, schemaname))
			if err then
				error("save error: " .. err)
			end

			return "save complete with " .. result.total_parts .. " parts and " .. result.total_size .. " bytes"
		end)
	end
})
