
minetest.register_chatcommand("bx_pos1", {
  description = "Set position 1",
  func = function(name)
    local player = minetest.get_player_by_name(name)
    if player then
      local pos = vector.round(player:get_pos())
      blockexchange.set_pos(1, name, pos)
    end
  end
})

minetest.register_chatcommand("bx_pos2", {
  description = "Set position 2",
  func = function(name)
    local player = minetest.get_player_by_name(name)
    if player then
      local pos = vector.round(player:get_pos())
      blockexchange.set_pos(2, name, pos)
    end
  end
})
