minetest.register_chatcommand("bx_emerge", {
	description = "Emerges the selected region",
  privs = { blockexchange = true },
	func = function(name)
    local pos1 = blockexchange.get_pos(1, name)
    local pos2 = blockexchange.get_pos(2, name)

    if not pos1 or not pos2 then
      return false, "you need to set /bx_pos1 and /bx_pos2 first!"
    end

    blockexchange.emerge(name, pos1, pos2)
		return true
  end
})
