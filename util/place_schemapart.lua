
-- places a schemapart in the world with respect to the origin point
-- returns the placed pos1, pos2 as well as the data and metadata
-- TODO: alignment
function blockexchange.place_schemapart(schemapart, origin, update_light)
	local data, metadata = blockexchange.unpack_schemapart(schemapart)

	local pos1 = vector.add(origin, {
		x = schemapart.offset_x,
		y = schemapart.offset_y,
		z = schemapart.offset_z
	})
	local pos2 = vector.add(pos1, vector.subtract(metadata.size, 1))
	blockexchange.deserialize_part(pos1, pos2, data, metadata, update_light);

	return pos1, pos2, data, metadata
end