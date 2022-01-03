
function blockexchange.is_player_in_area(player, pos1, pos2)
    pos1, pos2 = blockexchange.sort_pos(pos1, pos2)
    local ppos = player:get_pos()
    return ppos.x >= pos1.x and ppos.x <= pos2.x and
        ppos.y >= pos1.y and ppos.y <= pos2.y and
        ppos.z >= pos1.z and ppos.z <= pos2.z
end