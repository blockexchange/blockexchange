

minetest.register_chatcommand("bx_allocate", {
  params = "<username> <schemaname>",
	description = "Show where the selected schema would end up",
  privs = { blockexchange = true },
	func = function(name, param)
    local pos1 = blockexchange.get_pos(1, name)

    if not pos1 then
      return false, "you need to set /bx_pos1 first!"
    end

    local _, _, username, schemaname = string.find(param, "^([^%s]+)%s+(.*)$")
    if not username or not schemaname then
      return false, "Usage: /bx_allocate <username> <schemaname>"
    end

		blockexchange.allocate(name, pos1, username, schemaname)
		return true
  end
})
