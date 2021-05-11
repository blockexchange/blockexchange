

minetest.register_chatcommand("bx_allocate_local", {
  params = "<schemaname>",
	description = "Show where the selected schema would end up",
  privs = { blockexchange = true },
	func = function(name, schemaname)
    local pos1 = blockexchange.get_pos(1, name)

    if not pos1 then
      return false, "you need to set /bx_pos1 first!"
    end

    if not schemaname or schemaname == "" then
      return false, "Usage: /bx_allocate_local <schemaname>"
    end

		blockexchange.allocate(name, pos1, name, schemaname, true)
		return true
  end
})
