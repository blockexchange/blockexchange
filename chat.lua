minetest.register_chatcommand("bx_save", {
  params = "<name> <description>",
	description = "",
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

minetest.register_chatcommand("bx_load", {
  params = "<username> <schemaname>",
	description = "",
	func = function(name, param)
    local _, _, username, schemaname = string.find(param, "^([^%s]+)%s+([^%s]+)%s*$")

    if not username or not schemaname then
      return false, "Usage: /bx_load <username> <schemaname>"
    end

    local pos1 = blockexchange.pos1[name]

    if not pos1 then
      return false, "you need to set /bx_pos1 first!"
    end

		blockexchange.download(name, pos1, username, schemaname)
		return true
  end
})

minetest.register_chatcommand("bx_load_here", {
  params = "<username> <schemaname>",
	description = "",
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

minetest.register_chatcommand("bx_allocate", {
  params = "<username> <schemaname>",
	description = "",
	func = function(name, param)
    local pos1 = blockexchange.pos1[name]

    if not pos1 then
      return false, "you need to set /bx_pos1 first!"
    end

    local _, _, username, schemaname = string.find(param, "^([^%s]+)%s+([^%s]+)%s*$")
    if not username or not schemaname then
      return false, "Usage: /bx_allocate <username> <schemaname>"
    end

		blockexchange.allocate(name, pos1, username, schemaname)
		return true
  end
})

minetest.register_chatcommand("bx_info", {
	description = "Shows infos about the remote blockexchange",
	func = function(name)
		blockexchange.api.get_info(function(info)
			local msg = ""
			msg = msg .. "Connected exchange name: '" .. info.name .. "' owner: '" .. info.owner .. "'"
			msg = msg .. " Remote version: " .. info.api_version_major .. "." .. info.api_version_minor
			msg = msg .. " Local version: " .. blockexchange.api_version_major
			msg = msg .. " URL: " .. blockexchange.url

			minetest.chat_send_player(name, msg)
		end,
		function(http_code)
			minetest.chat_send_player(name, "HTTP-Error: " .. (http_code or "unknown"))
		end)

		return true
  end
})
