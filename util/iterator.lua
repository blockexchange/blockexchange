

function blockexchange.iterator(origin, pos1, pos2)
    local base_pos1 = blockexchange.get_base_pos(origin, pos1)
    local base_pos2 = blockexchange.get_base_pos(origin, pos2)

    local part_length = 16
    local pos

    return function()
        if not pos then
            pos = {x = base_pos1.x, y = base_pos1.y, z = base_pos1.z}
        else
            pos.x = pos.x + part_length
            if pos.x > base_pos2.x then
                pos.x = base_pos1.x
                pos.z = pos.z + part_length
                if pos.z > base_pos2.z then
                    pos.z = base_pos1.z
                    pos.y = pos.y + part_length
                    if pos.y > base_pos2.y then
                        pos = nil
                    end
                end
            end
        end
        return pos
    end
end