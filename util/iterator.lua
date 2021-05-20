
local part_length = 16


function blockexchange.iterator(origin, pos1, pos2)
    local base_pos1 = blockexchange.get_base_pos(origin, pos1)
    local base_pos2 = blockexchange.get_base_pos(origin, pos2)

    local pos
    local count = 0

    local total_parts = math.max(math.ceil(math.abs(pos1.x - pos2.x) / part_length), 1) *
        math.max(math.ceil(math.abs(pos1.y - pos2.y) / part_length), 1) *
        math.max(math.ceil(math.abs(pos1.z - pos2.z) / part_length), 1)

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
        local progress = count / total_parts
        local abs_pos
        if pos then
            -- calculate absolute position with relation to the origin point
            abs_pos = vector.add(origin, pos)
        end
        return abs_pos, pos, progress
    end
end