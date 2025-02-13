---------
-- async schema load command

--- load a schematic asynchronously
-- @param playername the playername to use in messages
-- @param pos1 lower position to load
-- @param username the username/owner of the schema
-- @param schemaname the name of the schema
-- @param[opt] from_mtime start with block mtime
-- @return a promise that resolves if the operation is complete
-- @return the job context
function blockexchange.load(playername, pos1, username, schemaname, from_mtime)
	local ctx = {
		type = "download",
		playername = playername,
		username = username,
		schemaname = schemaname,
		pos1 = pos1,
		current_part = 0,
		progress_percent = 0,
		from_mtime = from_mtime or 0,
		promise = Promise.new()
	}

	blockexchange.api.get_schema_by_name(username, schemaname, true):next(function(schema)
		if not schema then
			ctx.promise:reject("Schema not found: '" .. username .. "/" .. schemaname .. "'")
			return
		end
		ctx.pos2 = vector.add(pos1, blockexchange.get_schema_size(schema))
		ctx.schema = schema
		-- calculate origin point
		ctx.origin = ctx.pos1
		-- fetch total parts
		return blockexchange.api.count_next_schemapart_by_mtime(schema.uid, ctx.from_mtime)
	end):next(function(total_parts)
		if total_parts then
			ctx.total_parts = total_parts
			blockexchange.load_worker(ctx)
		end
	end)

	return ctx.promise, ctx
end
