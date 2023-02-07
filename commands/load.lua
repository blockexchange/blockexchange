---------
-- async schema load command

--- load a schematic asynchronously
-- @param playername the playername to use in messages
-- @param pos1 lower position to load
-- @param username the username/owner of the schema
-- @param schemaname the name of the schema
-- @param[opt] local_load load from the filesystem
-- @param[opt] from_mtime start with block mtime
-- @return a promise that resolves if the operation is complete
-- @return the job context
function blockexchange.load(playername, pos1, username, schemaname, local_load, from_mtime)
	local ctx = {
		type = "download",
		local_load = local_load,
		playername = playername,
		username = username,
		schemaname = schemaname,
		pos1 = pos1,
		current_part = 0,
		progress_percent = 0,
		from_mtime = from_mtime or 0,
		promise = Promise.new()
	}

	if local_load then
		local filename = blockexchange.get_local_filename(schemaname)
		ctx.zipfile = io.open(filename, "rb")
		if not ctx.zipfile then
			ctx.promise:reject("file not found: " .. filename)
			return ctx.promise
		end
		local z, err_msg = mtzip.unzip(ctx.zipfile)
		if err_msg then
			ctx.promise:reject("unzip error: " .. err_msg)
			return ctx.promise
		end
		ctx.zip = z

		local schema_str
		schema_str, err_msg = ctx.zip:get("schema.json", true)
		if err_msg then
			ctx.promise:reject("schema.json error: " .. err_msg)
			return ctx.promise
		end
		local schema = minetest.parse_json(schema_str)

		local pos2 = vector.add(pos1, blockexchange.get_schema_size(schema))
		pos2 = vector.subtract(pos2, 1)

		local total_parts = blockexchange.count_schemaparts(pos1, pos2)

		ctx.pos2 = pos2
		ctx.origin = ctx.pos1

		ctx.iterator = blockexchange.iterator(ctx.origin, ctx.pos1, ctx.pos2)
		ctx.total_parts = total_parts
		ctx.schema = {}

		blockexchange.set_pos(2, playername, pos2)
		blockexchange.load_worker(ctx)
	else
		blockexchange.api.get_schema_by_name(username, schemaname, true):next(function(schema)
			ctx.pos2 = vector.add(pos1, blockexchange.get_schema_size(schema))
			ctx.schema = schema
			-- calculate origin point
			ctx.origin = ctx.pos1
			-- fetch total parts
			return blockexchange.api.count_next_schemapart_by_mtime(schema.id, ctx.from_mtime)
		end):next(function(total_parts)
			ctx.total_parts = total_parts
			blockexchange.load_worker(ctx)
		end):catch(function()
			ctx.promise:reject("schema not found")
		end)
	end

	return ctx.promise, ctx
end
