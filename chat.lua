minetest.register_chatcommand("blockexchange_save", {
  params = "",
	description = "",
	func = function(name)
    local pos1 = worldedit.pos1[name]
    local pos2 = worldedit.pos2[name]
		local description = ""
		local tags = {}

    blockexchange.upload(pos1, pos2, description, tags)
		return true
  end
})

minetest.register_chatcommand("blockexchange_load", {
  params = "<schemaid>",
	description = "",
	func = function(name, param)
    local pos1 = worldedit.pos1[name]
		blockexchange.download(pos1, param)
		return true
  end
})

minetest.register_chatcommand("blockexchange_info", {
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
