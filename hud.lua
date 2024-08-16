local HUD_POSITION = { x = 0.1, y = 0.8 }
local HUD_ALIGNMENT = { x = 1, y = 0 }

local HUD_ICON_KEY = "icon"
local HUD_TEXT_KEY = "text"

-- playername -> data
local hud = {}

local function update_player_hud(player)
	local playername = player:get_player_name()

	local hud_data = hud[playername]
	if not hud_data then
		return
	end

	local ctx = blockexchange.get_job_context(playername)
	local pos = player:get_pos()
	local area = blockexchange.get_area(pos)
	local hud_info_available = ctx or area

	if hud_info_available and not hud_data.active then
		-- enable
		hud_data.active = true
	elseif not hud_info_available and hud_data.active then
		-- disable
		hud_data.active = false
		player:hud_change(hud_data[HUD_ICON_KEY], "text", "")
		player:hud_change(hud_data[HUD_TEXT_KEY], "text", "")
	end

	local icon_name = ""
	local text = ""
	local color = 0x00ff00

	if ctx then
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

		elseif ctx.type == "upload-update" then
			icon_name = "blockexchange_upload.png"
			text = "Updating upload, progress: " .. ctx.progress_percent .. " %"

		elseif ctx.type == "cleanup" then
			icon_name = "blockexchange_cleanup.png"
			text = "Cleanup, progress: " .. ctx.progress_percent .. " %"

		end

	elseif area then
		icon_name = "blockexchange_info.png"
		text = string.format("BX-Area: '%s' Schema: %s/%s", area.id, area.username, area.name)
		if area.autosave then
			text = text .. " [Autosave]"
		end
		if blockexchange.is_area_autosaving(area.id) then
			icon_name = "blockexchange_upload.png"
		end
	end

	if icon_name ~= "" and text ~= "" then
		-- apply changes
		player:hud_change(hud_data[HUD_ICON_KEY], "text", icon_name)
		player:hud_change(hud_data[HUD_TEXT_KEY], "text", text)
		player:hud_change(hud_data[HUD_TEXT_KEY], "number", color)
	end

end


-- state tracking

local function create_hud(player)
	local meta = player:get_meta()
	if meta:get_int("bx_hud") ~= 1 then
		-- not enabled
		return
	end

	local playername = player:get_player_name()
	local hud_data = hud[playername]

	if hud_data then
		-- already enabled
		return
	end

	hud_data = {}
	hud[playername] = hud_data
	hud_data[HUD_ICON_KEY] = player:hud_add({
		[minetest.features.hud_def_type_field and "type" or "hud_elem_type"] = "image",
		position = HUD_POSITION,
		offset = {x=0, y=0},
		text = "",
		alignment = HUD_ALIGNMENT,
		scale = { x = 1, y = 1 },
	})

	hud_data[HUD_TEXT_KEY] = player:hud_add({
		[minetest.features.hud_def_type_field and "type" or "hud_elem_type"] = "text",
		position = HUD_POSITION,
		offset = {x=20, y=0},
		text = "",
		alignment = HUD_ALIGNMENT,
		scale = { x = 100, y = 100 },
		number = 0x00FF00
	})
end

local function remove_hud(player)
	local playername = player:get_player_name()
	local hud_data = hud[playername]
	if hud_data then
		player:hud_remove(hud_data[HUD_ICON_KEY])
		player:hud_remove(hud_data[HUD_TEXT_KEY])
		hud[playername] = nil
	end
end

-- update periodically
local function update_hud()
	for _, player in ipairs(minetest.get_connected_players()) do
		update_player_hud(player)
	end
	minetest.after(0.5, update_hud)
end
minetest.after(0.5, update_hud)

-- remove on leave
minetest.register_on_leaveplayer(remove_hud)
-- create on join
minetest.register_on_joinplayer(create_hud)

function blockexchange.set_player_hud(playername, enabled)
	local player = minetest.get_player_by_name(playername)
	if not player then
		return
	end

	local meta = player:get_meta()
	if enabled then
		meta:set_int("bx_hud", 1)
		create_hud(player)
		return true, "Hud enabled"
	else
		meta:set_int("bx_hud", 0)
		remove_hud(player)
		return true, "Hud disabled"
	end
end

minetest.register_chatcommand("bx_hud", {
	description = "Enables or disables the blockexchange hud",
	params = "bx_hud [on|off]",
	func = function(name, param)
		local enabled = param == "on"
		blockexchange.set_player_hud(name, enabled)

		return true, enabled and "Hud enabled" or "Hud disabled"
  end
})
