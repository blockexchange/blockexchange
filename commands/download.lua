
function blockexchange.download(playername, pos1, username, schemaname)
	local ctx = {
		type = "download",
		playername = playername,
		username = username,
		schemaname = schemaname,
		pos1 = pos1,
		current_pos = table.copy(pos1),
		current_part = 0,
		progress_percent = 0
	}

	blockexchange.api.get_schema_by_name(username, schemaname, true, function(schema)
		ctx.pos2 = vector.add(pos1, {x=schema.max_x, y=schema.max_y, z=schema.max_z})
		ctx.schema = schema
		ctx.total_parts =
	    math.ceil(schema.max_x / blockexchange.part_length) *
	    math.ceil(schema.max_y / blockexchange.part_length) *
	    math.ceil(schema.max_z / blockexchange.part_length)

		blockexchange.download_worker(ctx)
	end,
	function()
		minetest.chat_send_player(ctx.playername, "Schema not found: '" ..
			username .. "/" .. schemaname .. "'")
	end)

	return ctx
end
