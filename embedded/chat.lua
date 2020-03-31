

minetest.register_chatcommand("/pos1", {
	description = "",
	func = function(name)
		local player = minetest.get_player_by_name(name)
		if player then
			local pos = vector.floor(player:get_pos())
			minetest.chat_send_player(name, "Position 1 set to " .. minetest.pos_to_string(pos))
			worldedit.pos1[name] = pos
		end
  end
})

minetest.register_chatcommand("/pos2", {
	description = "",
	func = function(name)
		local player = minetest.get_player_by_name(name)
		if player then
			local pos = vector.floor(player:get_pos())
			minetest.chat_send_player(name, "Position 2 set to " .. minetest.pos_to_string(pos))
			worldedit.pos2[name] = pos		end
  end
})
