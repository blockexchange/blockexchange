local HUD_POSITION = { x = 0.09, y = 0.1 }
local HUD_ALIGNMENT = { x = 1, y = 0 }

local HUD_ICON_KEY = "icon"
local HUD_TEXT_KEY = "text"

-- playername -> data
local hud = {}

local function update_player_hud(player)
	local playername = player:get_player_name()
	local hud_data = hud[playername]
	local ctx = blockexchange.get_job_context(playername)

	if ctx and not hud_data.active then
		-- enable
		hud_data.active = true
	elseif not ctx and hud_data.active then
		-- disable
		hud_data.active = false
		player:hud_change(hud_data[HUD_ICON_KEY], "text", "")
		player:hud_change(hud_data[HUD_TEXT_KEY], "text", "")
	end

	if ctx then
		local icon_name = ""
		local text = ""

		if ctx.type == "emerge" then
			icon_name = "blockexchange_emerge.png"
			text = "Emerging, progress: " .. ctx.progress_percent .. " %"

		elseif ctx.type == "protectioncheck" then
			icon_name = "blockexchange_protectioncheck.png"
			text = "Protection-check, progress: " .. ctx.progress_percent .. " %"

		elseif ctx.type == "download" then
			icon_name = "blockexchange_download.png"
			text = "Downloading '" .. ctx.username .. "/" .. ctx.schemaname .. "', progress: " .. ctx.progress_percent .. " %"

		elseif ctx.type == "upload" then
			icon_name = "blockexchange_upload.png"
			text = "Uploading '" .. ctx.username .. "/" .. ctx.schemaname .. "', progress: " .. ctx.progress_percent .. " %"

		end

		player:hud_change(hud_data[HUD_ICON_KEY], "text", icon_name)
		player:hud_change(hud_data[HUD_TEXT_KEY], "text", text)
	end

end


-- state tracking

-- update
local function update_hud()
	for _, player in ipairs(minetest.get_connected_players()) do
		update_player_hud(player)
	end
	minetest.after(0.5, update_hud)
end
minetest.after(0.5, update_hud)

-- remove
minetest.register_on_leaveplayer(function(player)
	-- remove stale hud data
	local playername = player:get_player_name()
	hud[playername] = nil
end)

-- create
minetest.register_on_joinplayer(function(player)
	-- create hud data
	local hud_data = {}

	local playername = player:get_player_name()
	hud[playername] = hud_data

	hud_data[HUD_ICON_KEY] = player:hud_add({
		hud_elem_type = "image",
		position = HUD_POSITION,
		offset = {x=0, y=0},
		text = "",
		alignment = HUD_ALIGNMENT,
		scale = { x = 1, y = 1 },
	})

	hud_data[HUD_TEXT_KEY] = player:hud_add({
		hud_elem_type = "text",
		position = HUD_POSITION,
		offset = {x=20, y=0},
		text = "",
		alignment = HUD_ALIGNMENT,
		scale = { x = 100, y = 100 },
		number = 0x00FF00
	})
end)
