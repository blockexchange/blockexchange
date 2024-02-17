--- returns the pointed position
function blockexchange.get_pointed_position(player, distance)
    distance = distance or 10
    local ppos = player:get_pos()
    local eye_height = player:get_properties().eye_height
    ppos = vector.add(ppos, {x=0, y=eye_height, z=0})
    local look_dir = player:get_look_dir()

    local pos = vector.add(ppos, vector.multiply(look_dir, distance))
    return vector.round(pos)
end
