local FORMNAME = "blockexchange_controller"

local function show_formspec(pos, playername)
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
		print("TODO: upload")
	end

	if fields.mark then
		print("TODO: mark")
	end
end)


minetest.register_node("blockexchange:controller", {
	description = "Blockexchange controller",
	tiles = {
		"blockexchange_controller.png"
	},
	groups = {
		cracky=3,
		oddly_breakable_by_hand=3
	},
	on_rightclick = function(pos, _, player)
		local meta = minetest.get_meta(pos)
		local playername = player:get_player_name()
		if meta:get_string("schema") ~= "" then
			show_formspec(pos, playername)
		else
			minetest.chat_send_player(playername, "Initialize this controller by uploading the surrounding area")
		end
	end,
})

function blockexchange.program_controller(pos, playername, schema, origin)
	local meta = minetest.get_meta(pos)
	meta:set_int("version", 1)
	meta:set_string("owner", playername)
	meta:set_string("schema", minetest.serialize(schema))
	meta.set_string("origin", minetest.serialize(origin))
	meta:set_string("infotext",
		"Controller for schema '".. schema.name .. "' " ..
		"owned by '" .. playername .. "'"
	)
end