minetest.register_chatcommand("bx_load", {
  params = "<username> <schemaname>",
	description = "Downloads a schema from the blockexchange to the selected pos1",
  privs = { blockexchange = true },
	func = function(name, param)
    local _, _, username, schemaname = string.find(param, "^([^%s]+)%s+([^%s]+)%s*$")

    if not username or not schemaname then
      return false, "Usage: /bx_load <username> <schemaname>"
    end

    local pos1 = blockexchange.get_pos(1, name)

    if not pos1 then
      return false, "you need to set /bx_pos1 first!"
    end

		blockexchange.download(name, pos1, username, schemaname)
		return true
  end
})
