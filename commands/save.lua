---------
-- async schema save command

--- save a schematic asynchronously
-- @param playername the playername to use in messages
-- @param pos1 lower position to save
-- @param pos2 upper position to save
-- @param name the name of the schema
-- @param local_save save to the filesystem
-- @return a promise that resolves if the operation is complete

function blockexchange.save(playername, pos1, pos2, name, local_save)
	pos1, pos2 = blockexchange.sort_pos(pos1, pos2)

	local total_parts = blockexchange.count_schemaparts(pos1, pos2)
	local token = blockexchange.get_token(playername)
	local claims = blockexchange.parse_token(token)
	local license = blockexchange.get_license(playername)
	local iterator = blockexchange.iterator(pos1, pos1, pos2)

	local ctx = {
		local_save = local_save,
		playername = playername,
		schemaname = name,
		token = token,
		origin = pos1,
		pos1 = pos1,
		pos2 = pos2,
		iterator = iterator,
		current_pos = iterator(),
		current_part = 0,
		total_parts = total_parts,
		progress_percent = 0,
		mod_names = {},
		promise = Promise.new()
	}

	local create_schema = {
		size_x_plus = pos2.x - pos1.x + 1,
		size_y_plus = pos2.y - pos1.y + 1,
		size_z_plus = pos2.z - pos1.z + 1,
		size_x_minus = 0,
		size_y_minus = 0,
		size_z_minus = 0,
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
			ctx.promise:reject(msg)
		end)
	end

	return ctx.promise
end
