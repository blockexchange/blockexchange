
function blockexchange.iterator(pos1, pos2, part_length)
	local pos
  local i = 0
  local total_parts =
    math.ceil(math.abs(pos1.x - pos2.x) / part_length) *
    math.ceil(math.abs(pos1.y - pos2.y) / part_length) *
    math.ceil(math.abs(pos1.z - pos2.z) / part_length)

	return function()
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
    i = i + 1
		return pos, i, total_parts
	end
end
