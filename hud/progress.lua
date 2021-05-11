local HUD_POSITION = { x = 0.09, y = 0.4 }
local HUD_ALIGNMENT = { x = 1, y = 0 }

local hud = {} -- playername -> data

-- blockexchange.hud_update_progress("somedude", "Upload 'xy'", 90, 0x00FF00)

function blockexchange.hud_update_progress(playername, taskname, progress, color)
	local hud_data = hud[playername]
	local player = minetest.get_player_by_name(playername)
	if not player then
		return
	end

	local txt = taskname .. " " .. math.floor(progress*10)/10 .. " %"

	if not hud_data[taskname] then
		-- count existing entries
		local count = 0
		for _ in pairs(hud_data) do
			count = count + 1
		end
		local offset = { x=0, y=count*18 }

		-- create element
		hud_data[taskname] = player:hud_add({
			hud_elem_type = "text",
			position = HUD_POSITION,
			offset = offset,
			text = txt,
			alignment = HUD_ALIGNMENT,
			scale = { x = 100, y = 100 },
			number = color
		})
	else
		-- update element
		player:hud_change(hud_data[taskname], "text", txt)
		player:hud_change(hud_data[taskname], "number", color)
	end
end

function blockexchange.hud_remove(playername, taskname)
	local hud_data = hud[playername]
	local player = minetest.get_player_by_name(playername)

	if player and hud_data[taskname] then
		-- remove hud element
		player:hud_remove(hud_data[taskname])
		hud_data[taskname] = nil
	end
end

-- session/state tracking

minetest.register_on_leaveplayer(function(player)
	-- remove stale hud data
	local playername = player:get_player_name()
	hud[playername] = nil
end)

minetest.register_on_joinplayer(function(player)
	-- create hud data
	local hud_data = {}

	local playername = player:get_player_name()
	hud[playername] = hud_data
end)
