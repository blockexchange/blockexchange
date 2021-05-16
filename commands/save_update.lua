
function blockexchange.save_update(playername, origin, pos1, pos2, username, schemaname)
	pos1, pos2 = blockexchange.sort_pos(pos1, pos2)

	local total_parts = blockexchange.count_schemaparts(pos1, pos2)
	local token = blockexchange.get_token(playername)
	local iterator = blockexchange.iterator(origin, pos1, pos2)

	local ctx = {
		playername = playername,
		token = token,
		origin = origin,
		pos1 = pos1,
		pos2 = pos2,
		username = username,
		schemaname = schemaname,
		iterator = iterator,
		current_pos = iterator(),
		current_part = 0,
		total_parts = total_parts,
		progress_percent = 0,
		mod_names = {},
		promise = Promise.new()
	}

	blockexchange.api.get_schema_by_name(username, schemaname):next(function(schema)
		ctx.schema = schema
		-- Start async worker
		blockexchange.save_update_worker(ctx)

	end):catch(function(err)
		ctx.promise:reject(err)
	end)

	return ctx.promise
end
