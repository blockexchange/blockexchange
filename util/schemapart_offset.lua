
function blockexchange.get_schemapart_offset(origin, pos)
    local relative_pos = vector.subtract(pos, origin)
    local block_pos = vector.divide(relative_pos, 16)

    local min_pos = vector.multiply(vector.floor(block_pos), 16)
    local max_pos = vector.add(min_pos, 15)
    return min_pos, max_pos
end