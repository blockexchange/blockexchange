
function blockexchange.check_size(pos1, pos2)
    return math.abs(pos1.x - pos2.x) <= blockexchange.max_size and
        math.abs(pos1.y - pos2.y) <= blockexchange.max_size and
        math.abs(pos1.z - pos2.z) <= blockexchange.max_size
end