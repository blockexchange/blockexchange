
function blockexchange.save(playername, pos1, pos2, name, local_save)
	pos1, pos2 = blockexchange.sort_pos(pos1, pos2)

	local total_parts =
		math.ceil(math.abs(pos1.x - pos2.x) / blockexchange.part_length) *
		math.ceil(math.abs(pos1.y - pos2.y) / blockexchange.part_length) *
		math.ceil(math.abs(pos1.z - pos2.z) / blockexchange.part_length)

	local token = blockexchange.get_token(playername)
	local claims = blockexchange.parse_token(token)
	local license = blockexchange.get_license(playername)

	local ctx = {
		local_save = local_save,
		type = "upload",
		playername = playername,
		schemaname = name,
		token = token,
		pos1 = pos1,
		pos2 = pos2,
		current_pos = table.copy(pos1),
		current_part = 0,
		total_parts = total_parts,
		progress_percent = 0,
		mod_names = {}
	}

	local create_schema = {
		size_x_plus = pos2.x - pos1.x + 1,
		size_y_plus = pos2.y - pos1.y + 1,
		size_z_plus = pos2.z - pos1.z + 1,
		size_x_minus = 0,
		size_y_minus = 0,
		size_z_minus = 0,
		part_length = blockexchange.part_length,
		description = "",
		license = license,
		name = name
	  }

	if local_save then
		-- offline, local saving
		blockexchange.create_local_schema(create_schema)

		-- start save worker with context
		blockexchange.save_worker(ctx)
	else
		-- online
		blockexchange.api.create_schema(token, create_schema):next(function(schema)
			ctx.schema = schema
			minetest.log("action", "[blockexchange] schema created with id: " .. schema.id)
			minetest.chat_send_player(playername,
				"[blockexchange] schema created with id: " ..
				minetest.colorize("#00ff00", schema.id)
			)

			blockexchange.register_area(ctx.pos1, ctx.pos2, {
				type = "upload",
				schemaname = name,
				username = claims.username,
				owner = playername,
				origin = ctx.pos1
			})

			-- start save worker with context
			blockexchange.save_worker(ctx)
		end):catch(function(http_code)
			local msg = "[blockexchange] create schema failed with http code: " .. (http_code or "unknown")
			minetest.log("error", msg)
			minetest.chat_send_player(playername, minetest.colorize("#ff0000", msg))
			ctx.failed = true
		end)
	end

	return ctx
end
