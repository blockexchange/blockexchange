
-- returns either the area with the area_id or the area the player is currently standing in
function blockexchange.select_player_area(name, area_id)
    local player = minetest.get_player_by_name(name)
    if not player and not area_id then
        return nil, "not enough info to select area"
    end

    if not area_id or area_id == "" then
        -- use the area_id of the players current position, if available
        local ppos = player:get_pos()
        local area = blockexchange.get_area(ppos)
        if area then
            area_id = area.id
        else
            return nil, "No area found at the current position"
        end
    end

    local area = blockexchange.get_area_by_id(area_id)
    if not area then
        return nil, "Area '" .. area_id .. "' not found"
    end

    return area
end