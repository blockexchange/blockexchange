minetest.register_chatcommand("blockexchange_save", {
  params = "",
	description = "",
	func = function(name)
    local pos1 = worldedit.pos1[name]
    local pos2 = worldedit.pos2[name]
		local description = ""
		local tags = {}

    blockexchange.upload(name, pos1, pos2, description, tags)
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



local pos1_player_map = {}
local pos2_player_map = {}

minetest.register_chatcommand("blockexchange_pos1", {
	description = "",
	func = function(name)
		local player = minetest.get_player_by_name(name)
		if player then
			local pos = vector.floor(player:get_pos())
			minetest.chat_send_player(name, "Position 1 set to " .. minetest.pos_to_string(pos))
			blockexchange.pos1[name] = pos

			if pos1_player_map[name] then
				player:hud_remove(pos1_player_map[name])
			end

			pos1_player_map[name] = player:hud_add({
				hud_elem_type = "waypoint",
				name = "Position 1",
				text = "m",
				number = 0xFF0000,
				world_pos = pos
			})
		end
  end
})

minetest.register_chatcommand("blockexchange_pos2", {
	description = "",
	func = function(name)
		local player = minetest.get_player_by_name(name)
		if player then
			local pos = vector.floor(player:get_pos())
			minetest.chat_send_player(name, "Position 2 set to " .. minetest.pos_to_string(pos))
			blockexchange.pos2[name] = pos

			if pos2_player_map[name] then
				player:hud_remove(pos2_player_map[name])
			end

			pos2_player_map[name] = player:hud_add({
				hud_elem_type = "waypoint",
				name = "Position 2",
				text = "m",
				number = 0xFF0000,
				world_pos = pos
			})

		end
  end
})


minetest.register_on_leaveplayer(function(player)
	local playername = player:get_player_name()
	pos1_player_map[playername] = nil
	pos2_player_map[playername] = nil
end)
