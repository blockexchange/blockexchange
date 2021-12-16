local FORMNAME = "blockexchange_controller"

function blockexchange.ui.show_controller_main(pos, playername)
	--local meta = minetest.get_meta(pos)

	local formspec = "size[8,6;]" ..
		"label[0,0;Blockexchange controller]" ..

		"button_exit[0,2.5;7,1;download;Download from blockexchange]" ..
		"button_exit[0,3.5;7,1;upload;Upload to blockexchange]" ..
		"button_exit[0,4.5;7,1;mark;Mark area]" ..
		"button_exit[0,5.5;7,1;abort;Abort]" ..
		""

	minetest.show_formspec(playername, FORMNAME .. ";" .. minetest.pos_to_string(pos), formspec)
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	local parts = formname:split(";")
	local name = parts[1]
	if name ~= FORMNAME then
		return
	end

	local pos = minetest.string_to_pos(parts[2])
	local playername = player:get_player_name()

	if minetest.is_protected(pos, playername) then
		return
	end

	if fields.download then
		print("TODO: download")
	end

	if fields.upload then
		-- full upload

		local meta = minetest.get_meta(pos)
		local origin = minetest.deserialize(meta:get_string("origin"))
		local schema = minetest.deserialize(meta:get_string("schema"))
		local pos2 = vector.add(origin, vector.subtract({ x=schema.size_x, y=schema.size_y, z=schema.size_z }, 1))

		-- TODO: verify user
		local token = blockexchange.get_token(playername)
		local claims = blockexchange.parse_token(token)

		blockexchange.save_update(playername, origin, origin, pos2, claims.username, schema.name)
	end

	if fields.mark then
		local meta = minetest.get_meta(pos)
		local origin = minetest.deserialize(meta:get_string("origin"))
		local schema = minetest.deserialize(meta:get_string("schema"))

		local pos2 = vector.add(origin, vector.subtract({ x=schema.size_x, y=schema.size_y, z=schema.size_z }, 1))
		blockexchange.set_pos(1, playername, origin)
		blockexchange.set_pos(2, playername, pos2)
	end
end)
