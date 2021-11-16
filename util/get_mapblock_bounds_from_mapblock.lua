function blockexchange.get_mapblock_bounds_from_mapblock(mapblock)
	local min = vector.multiply(mapblock, 16)
	local max = vector.add(min, 15)
	return min, max
end