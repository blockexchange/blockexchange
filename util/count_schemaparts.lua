
function blockexchange.count_schemaparts(pos1, pos2)
    return math.ceil(math.abs(pos1.x - pos2.x + 1) / 16) *
        math.ceil(math.abs(pos1.y - pos2.y + 1) / 16) *
        math.ceil(math.abs(pos1.z - pos2.z + 1) / 16)
end