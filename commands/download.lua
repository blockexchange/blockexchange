
function blockexchange.download(playername, pos1, username, schemaname)
	local ctx = {
		type = "download",
		playername = playername,
		pos1 = pos1,
		current_pos = table.copy(pos1),
		current_part = 0,
		progress_percent = 0
	}

	table.insert(blockexchange.processes, ctx)

	blockexchange.api.get_schema_by_name(username, schemaname, function(schema)
		ctx.pos2 = vector.add(pos1, {x=schema.size_x, y=schema.size_y, z=schema.size_z})
		ctx.schema = schema
		ctx.total_parts =
	    math.ceil(schema.size_x / blockexchange.part_length) *
	    math.ceil(schema.size_y / blockexchange.part_length) *
	    math.ceil(schema.size_z / blockexchange.part_length)

		minetest.after(0, blockexchange.download_worker, ctx)
	end,
	function()
		minetest.chat_send_player(ctx.playername, "Schema not found: '" ..
			username .. "/" .. schemaname .. "'")
	end)

	return ctx
end
