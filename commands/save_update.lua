
function blockexchange.save_update(playername, origin, pos1, pos2, username, schemaname)
	pos1, pos2 = blockexchange.sort_pos(pos1, pos2)

	local total_parts =
		math.ceil(math.abs(pos1.x - pos2.x) / blockexchange.part_length) *
		math.ceil(math.abs(pos1.y - pos2.y) / blockexchange.part_length) *
		math.ceil(math.abs(pos1.z - pos2.z) / blockexchange.part_length)

	local token = blockexchange.get_token(playername)

	local ctx = {
		type = "upload_save",
		playername = playername,
		token = token,
		origin = origin,
		pos1 = pos1,
		pos2 = pos2,
		username = username,
		schemaname = schemaname,
		current_pos = table.copy(pos1),
		current_part = 0,
		total_parts = total_parts,
		progress_percent = 0,
		mod_names = {},
		promise = Promise.new()
	}

	-- TODO

	return ctx.promise
end
