
minetest.register_chatcommand("bx_save", {
  params = "<name> <description>",
	description = "Uploads the selected region to the blockexchange server",
  privs = { blockexchange = true },
	func = function(name, param)
    local _, _, schemaname, description = string.find(param, "^([^%s]+)%s+(.*)$")
    if not schemaname or not description then
      return false, "Usage: /bx_save <schemaname> <description>"
    end

    local pos1 = blockexchange.get_pos(1, name)
    local pos2 = blockexchange.get_pos(2, name)

    if not pos1 or not pos2 then
      return false, "you need to set /bx_pos1 and /bx_pos2 first!"
    end

    blockexchange.upload(name, pos1, pos2, schemaname, description)
		return true
  end
})
