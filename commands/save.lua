---------
-- async schema save command

--- save a schematic asynchronously
-- @param playername the playername to use in messages
-- @param pos1 lower position to save
-- @param pos2 upper position to save
-- @param name the name of the schema
-- @param local_save save to the filesystem
-- @return a promise that resolves if the operation is complete
-- @return the job context
function blockexchange.save(playername, pos1, pos2, name, local_save)
	pos1, pos2 = blockexchange.sort_pos(pos1, pos2)

	local total_parts = blockexchange.count_schemaparts(pos1, pos2)
	local token = blockexchange.get_token(playername)
	local claims = blockexchange.get_claims(playername)
	local license = blockexchange.get_license(playername)
	local iterator = blockexchange.iterator(pos1, pos1, pos2)

	if not local_save and not token then
		return Promise.new():reject("not logged in")
	end

	local ctx = {
		type = "upload",
		local_save = local_save,
		playername = playername,
		username = claims and claims.username,
		schemaname = name,
		token = token,
		origin = pos1,
		pos1 = pos1,
		pos2 = pos2,
		iterator = iterator,
		current_pos = iterator(),
		current_part = 0,
		total_parts = total_parts,
		total_size = 0,
		progress_percent = 0,
		mod_names = {},
		promise = Promise.new()
	}

	local create_schema = {
		size_x = pos2.x - pos1.x + 1,
		size_y = pos2.y - pos1.y + 1,
		size_z = pos2.z - pos1.z + 1,
		description = "",
		license = license,
		name = name
	}

	if local_save then
		-- offline, local saving
		ctx.zipfile = io.open(blockexchange.get_local_filename(name), "wb")
		ctx.zip = mtzip.zip(ctx.zipfile)
		ctx.create_schema = create_schema

		-- start save worker with context
		blockexchange.save_worker(ctx)
	else
		-- online
		blockexchange.api.create_schema(token, create_schema):next(function(schema)
			ctx.schema = schema
			minetest.log("action", "[blockexchange] schema created with id: " .. schema.id)

			-- start save worker with context
			blockexchange.save_worker(ctx)
		end):catch(function(http_code)
			local msg = "[blockexchange] create schema failed with http code: " ..
				(http_code or "unknown") ..
				", you might have exceeded the upload limits"

			minetest.log("error", msg)
			ctx.promise:reject(msg)
		end)
	end

	return ctx.promise, ctx
end
