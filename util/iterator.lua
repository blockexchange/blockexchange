
local default_part_length = 16


function blockexchange.iterator(origin, pos1, pos2, part_length)
    pos1, pos2 = blockexchange.sort_pos(pos1, pos2)
    part_length = part_length or default_part_length

    local base_pos1 = blockexchange.get_base_pos(origin, pos1)
    local base_pos2 = blockexchange.get_base_pos(origin, pos2)

    local pos
    local count = 0

    local total_parts = math.max(math.ceil((pos2.x - pos1.x + 1) / part_length), 1) *
        math.max(math.ceil((pos2.y - pos1.y + 1) / part_length), 1) *
        math.max(math.ceil((pos2.z - pos1.z + 1) / part_length), 1)

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
        count = count + 1
        local progress = math.min(count / total_parts, 1)
        local abs_pos
        if pos then
            -- calculate absolute position with relation to the origin point
            abs_pos = vector.add(origin, pos)
        end
        return abs_pos, pos, progress
    end
end