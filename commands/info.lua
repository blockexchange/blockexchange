

minetest.register_chatcommand("bx_info", {
	description = "Shows infos about the remote blockexchange",
	func = function(name)
		blockexchange.api.get_info():next(function(info)
			local msg = ""
			msg = msg .. "Connected exchange name: '" .. info.name .. "' owner: '" .. info.owner .. "'"
			msg = msg .. " Remote version: " .. info.api_version_major .. "." .. info.api_version_minor
			msg = msg .. " Local version: " .. blockexchange.api_version_major
			msg = msg .. " URL: " .. blockexchange.url

			minetest.chat_send_player(name, msg)
		end):catch(function(err)
			minetest.chat_send_player(name, "Error: " .. (err or "unknown"))
		end)

		return true
  end
})
