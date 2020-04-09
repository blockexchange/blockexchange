
minetest.register_chatcommand("bx_save", {
  params = "<name> <description>",
	description = "Uploads the selected region to the blockexchange server",
  privs = { blockexchange = true },
	func = function(name, param)
    local _, _, schemaname, description = string.find(param, "^([^%s]+)%s+(.*)$")
    if not schemaname or not description then
      return false, "Usage: /bx_save <schemaname> <description>"
    end

    local pos1 = blockexchange.pos1[name]
    local pos2 = blockexchange.pos2[name]

    if not pos1 or not pos2 then
      return false, "you need to set /bx_pos1 and /bx_pos2 first!"
    end

    blockexchange.upload(name, pos1, pos2, schemaname, description)
		return true
  end
})



minetest.register_chatcommand("bx_load_here", {
  params = "<username> <schemaname>",
	description = "Downloads a schema from the blockexchange to the current position",
  privs = { blockexchange = true },
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if player then
			local pos = vector.floor(player:get_pos())
      blockexchange.set_pos(1, name, pos)
		end

    local _, _, username, schemaname = string.find(param, "^([^%s]+)%s+([^%s]+)%s*$")
    if not username or not schemaname then
      return false, "Usage: /bx_load_here <username> <schemaname>"
    end

    local pos1 = blockexchange.pos1[name]
		blockexchange.download(name, pos1, username, schemaname)
		return true
  end
})
