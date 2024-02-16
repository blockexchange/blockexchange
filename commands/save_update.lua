-- update a region
function blockexchange.save_update(playername, origin, pos1, pos2, username, schema_uid)
	pos1, pos2 = blockexchange.sort_pos(pos1, pos2)

	local total_parts = blockexchange.count_schemaparts(pos1, pos2)
	local token = blockexchange.get_token(playername)
	local iterator = blockexchange.iterator(origin, pos1, pos2)

	local ctx = {
		type = "upload-update",
		playername = playername,
		token = token,
		origin = origin,
		pos1 = pos1,
		pos2 = pos2,
		username = username,
		schema_uid = schema_uid,
		iterator = iterator,
		current_pos = iterator(),
		current_part = 0,
		total_parts = total_parts,
		progress_percent = 0,
		mod_names = {},
		promise = Promise.new()
	}

	-- Start async worker
	blockexchange.save_update_worker(ctx)

	return ctx.promise, ctx
end

-- update a region of a schema
function blockexchange.save_update_area(playername, pos1, pos2, save_pos1, save_pos2, username, schema_uid)
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

	return blockexchange.save_update(playername, pos1, abs_pos1, abs_pos2, username, schema_uid)
end

-- update a region on a single position
function blockexchange.save_update_pos(playername, pos1, pos2, pos, username, schema_uid)
	local offset_pos1, offset_pos2 = blockexchange.get_schemapart_offset(pos1, pos)
	local abs_pos1 = vector.add(pos1, offset_pos1)
	local abs_pos2 = vector.add(pos1, offset_pos2)

	abs_pos1, abs_pos2 = blockexchange.clip_area(pos1, pos2, abs_pos1, abs_pos2)
	return blockexchange.save_update(playername, pos1, abs_pos1, abs_pos2, username, schema_uid)
end
