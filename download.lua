
function blockexchange.download(playername, pos1, schema_uid)
	local ctx = {
		playername = playername,
		pos1 = pos1,
		current_pos = table.copy(pos1),
		current_part = 0
	}

	blockexchange.api.get_schema(schema_uid, function(schema)
		ctx.pos2 = vector.add(pos1, {x=schema.size_x, y=schema.size_y, z=schema.size_z})
		ctx.schema = schema
		ctx.total_parts =
	    math.ceil(math.abs(pos1.x - ctx.pos2.x) / blockexchange.part_length) *
	    math.ceil(math.abs(pos1.y - ctx.pos2.y) / blockexchange.part_length) *
	    math.ceil(math.abs(pos1.z - ctx.pos2.z) / blockexchange.part_length)

		minetest.after(0, blockexchange.download_worker, ctx)
	end)

	return ctx
end
