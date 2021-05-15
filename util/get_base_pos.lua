
function blockexchange.get_base_pos(origin, pos)
    local relative_pos = vector.subtract(pos, origin)
    return vector.multiply(vector.floor(vector.divide(relative_pos, 16)), 16)
end