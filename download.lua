
function blockexchange.download(pos1, schema_uid)
	blockexchange.api.get_schema(schema_uid, function(schema)
		local pos2 = vector.add(pos1, {x=schema.size_x, y=schema.size_y, z=schema.size_z})

		local total_parts =
	    math.ceil(math.abs(pos1.x - pos2.x) / blockexchange.part_length) *
	    math.ceil(math.abs(pos1.y - pos2.y) / blockexchange.part_length) *
	    math.ceil(math.abs(pos1.z - pos2.z) / blockexchange.part_length)

		local ctx = {
			pos1 = pos1,
			pos2 = pos2,
			current_pos = table.copy(pos1),
			schema = schema,
			current_part = 0,
			total_parts = total_parts
		}
		minetest.after(0, blockexchange.download_worker, ctx)
	end)
end
