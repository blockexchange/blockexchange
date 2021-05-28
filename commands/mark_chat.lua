
minetest.register_chatcommand("bx_mark", {
  description = "Selects the nearest blockexchange regions",
  privs = { blockexchange = true },
  func = function(name)
    local player = minetest.get_player_by_name(name)
    if not player then
      return false, "Player not found"
    end

    local pos = player:get_pos()
    local area = blockexchange.get_area(pos, pos)
    if not area then
      return false, "No area found at the current position"
    end

    blockexchange.set_pos(1, name, area.pos1)
    blockexchange.set_pos(2, name, area.pos2)

    return true, "Region marked"
  end
})
