
function blockexchange.get_schemapart_offset(origin, pos)
    local relative_pos = vector.subtract(pos, origin)
    local block_pos = vector.divide(relative_pos, 16)

    return vector.floor(block_pos)
end