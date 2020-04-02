
function blockexchange.download(pos1, schema_id)
	blockexchange.api.get_schema(schema_id, function(schema)
		local pos2 = vector.add(pos1, {x=schema.size_x, y=schema.size_y, z=schema.size_z})
		local ctx = {
			pos1 = pos1,
			pos2 = pos2,
			schema = schema,
			iterator = blockexchange.iterator(pos1, pos2, schema.part_length)
		}
		minetest.after(0, blockexchange.download_worker, ctx)
	end)
end
