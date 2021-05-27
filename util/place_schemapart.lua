
function blockexchange.place_schemapart(schemapart, origin)
    local data, metadata = blockexchange.unpack_schemapart(schemapart)

    -- TODO: align / negative offsets
	local pos1 = vector.add(origin, {
		x = schemapart.offset_x,
		y = schemapart.offset_y,
		z = schemapart.offset_z
	})
	local pos2 = vector.add(pos1, vector.subtract(metadata.size, 1))
	blockexchange.deserialize_part(pos1, pos2, data, metadata);

    return pos1, pos2, data, metadata
end