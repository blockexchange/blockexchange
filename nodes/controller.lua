
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
			blockexchange.ui.show_controller_main(pos, playername)
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
	meta:set_string("origin", minetest.serialize(origin))
	meta:set_string("infotext",
		"Controller for schema '".. schema.name .. "' " ..
		"owned by '" .. playername .. "'"
	)
end