
local function pos_setter(i)
  return function(name, param)
    if param and param ~= "" then
      -- manual coord input
      local pos = minetest.string_to_pos(param)
      if not pos then
        return false, "invalid position format: '" .. param .. "' expected: '(x,y,z)'"
      end
      blockexchange.set_pos(i, name, pos)
      return true, "Position " .. i .. " set to " .. minetest.pos_to_string(pos)
    else
      -- current player coords
      local player = minetest.get_player_by_name(name)
      if not player then
        return false, "Player '" .. name .. "' not online"
      end
      local pos = vector.round(player:get_pos())
      blockexchange.set_pos(i, name, pos)
      return true, "Position " .. i .. " set to " .. minetest.pos_to_string(pos)
    end
  end
end

minetest.register_chatcommand("bx_pos1", {
  description = "Set position 1",
  params = "[pos?]",
  func = pos_setter(1)
})

minetest.register_chatcommand("bx_pos2", {
  description = "Set position 2",
  params = "[pos?]",
  func = pos_setter(2)
})
