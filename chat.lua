minetest.register_chatcommand("bx_save", {
  params = "<description>",
	description = "",
	func = function(name, description)
    local pos1 = blockexchange.pos1[name]
    local pos2 = blockexchange.pos2[name]

    if not pos1 or not pos2 then
      return false, "you need to set /bx_pos1 and /bx_pos2 first!"
    end

		description = description or ""
		local tags = {}

    blockexchange.upload(name, pos1, pos2, description, tags)
		return true
  end
})

minetest.register_chatcommand("bx_load", {
  params = "<schemaid>",
	description = "",
	func = function(name, param)
    local pos1 = blockexchange.pos1[name]

    if not pos1 then
      return false, "you need to set /bx_pos1 first!"
    end

		blockexchange.download(name, pos1, param)
		return true
  end
})

minetest.register_chatcommand("bx_allocate", {
  params = "<schemaid>",
	description = "",
	func = function(name, param)
    local pos1 = blockexchange.pos1[name]

    if not pos1 then
      return false, "you need to set /bx_pos1 first!"
    end

		blockexchange.allocate(name, pos1, param)
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
