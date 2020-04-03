
function blockexchange.iterator_next(pos1, pos2, pos)
	local part_length = blockexchange.part_length

	if not pos then
		pos = {x = pos1.x, y = pos1.y, z = pos1.z}
	else
		pos.x = pos.x + part_length
		if pos.x >= pos2.x then
			pos.x = pos1.x
			pos.z = pos.z + part_length
			if pos.z >= pos2.z then
				pos.z = pos1.z
				pos.y = pos.y + part_length
				if pos.y >= pos2.y then
					pos = nil
				end
			end
		end
	end
	return pos
end
