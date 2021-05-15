local HUD_POSITION = { x = 0.05, y = 0.95 }
local HUD_ALIGNMENT = { x = 1, y = 0 }

local hud = {} -- playername -> data


local function hud_update(player)
	local playername = player:get_player_name()
	local hud_data = hud[playername]
	local pos = player:get_pos()

	local txt = ""
	local area = blockexchange.get_area(pos, pos)
	if area then
		txt = "Blockexchange: [" .. area.data.type .. "] " .. area.data.username .. "/" .. area.data.schemaname
	end

	player:hud_change(hud_data, "text", txt)
end

local function check_interval()
	for _, player in ipairs(minetest.get_connected_players()) do
		hud_update(player)
	end
	minetest.after(1, check_interval)
end
minetest.after(0, check_interval)

minetest.register_on_leaveplayer(function(player)
	-- remove stale hud data
	local playername = player:get_player_name()
	hud[playername] = nil
end)

minetest.register_on_joinplayer(function(player)
	-- create hud data
	local hud_data = player:hud_add({
		hud_elem_type = "text",
		position = HUD_POSITION,
		offset = {x=0, y=0},
		text = "",
		alignment = HUD_ALIGNMENT,
		scale = { x = 100, y = 100 },
		number = 0x0000FF
	})

	local playername = player:get_player_name()
	hud[playername] = hud_data
end)
