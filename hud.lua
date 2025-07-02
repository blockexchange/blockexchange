local HUD_POSITION = { x = 0.1, y = 0.8 }
local HUD_ALIGNMENT = { x = 1, y = 0 }

local HUD_ICON_KEY = "hud_icon_key"
local HUD_TEXT_KEY = "hud_text_key"

-- playername -> data
local hud = {}

local function update_player_hud(player)
	local playername = player:get_player_name()

	local hud_data = hud[playername]
	if not hud_data then
		return
	end

	-- area hud
	local pos = player:get_pos()
	local area = blockexchange.get_area(pos)
	local area_icon = ""
	local area_text = ""

	if area then
		-- player is in an area
		area_icon = "blockexchange_info.png"
		area_text = string.format("BX-Area: '%s' Schema: %s/%s", area.id, area.username, area.name)
		if area.autosave then
			area_text = area_text .. " [Autosave]"
		end
		if area.dirty then
			area_text = area_text .. " [Local changes]"
		end
		if blockexchange.is_area_autosaving(area.id) then
			area_icon = "blockexchange_upload.png"
		end
	end

	-- update hud area state if changed
	local area_state = area_icon .. "/" .. area_text
	if hud_data.area_state ~= area_state then
		player:hud_change(hud_data[HUD_ICON_KEY], "text", area_icon)
		player:hud_change(hud_data[HUD_TEXT_KEY], "text", area_text)
		hud_data.area_state = area_state
	end

	-- job hud info
	hud_data.used_slots = hud_data.used_slots or {} -- {true, nil, true, ...}
	local jobs = blockexchange.get_jobs(playername)
	for i, job in ipairs(jobs) do
		if not job.hud_setup then
			-- initialize hud
			-- get next free hud slot
			local slot = 1
			while hud_data.used_slots[slot] do
				slot = slot + 1
			end
			hud_data.used_slots[slot] = true
			local y_offset = slot * 20

			job[HUD_ICON_KEY] = player:hud_add({
				[minetest.features.hud_def_type_field and "type" or "hud_elem_type"] = "image",
				position = HUD_POSITION,
				offset = {x=0, y=y_offset},
				text = "",
				alignment = HUD_ALIGNMENT,
				scale = { x = 1, y = 1 },
			})

			job[HUD_TEXT_KEY] = player:hud_add({
				[minetest.features.hud_def_type_field and "type" or "hud_elem_type"] = "text",
				position = HUD_POSITION,
				offset = {x=20, y=y_offset},
				text = "",
				alignment = HUD_ALIGNMENT,
				scale = { x = 100, y = 100 },
				number = 0x00FF00
			})

			job.promise:finally(function()
				-- remove hud
				player:hud_remove(job[HUD_ICON_KEY])
				player:hud_remove(job[HUD_TEXT_KEY])
				hud_data.used_slots[slot] = nil
			end)

			job.hud_setup = true
		end

		-- update hud
		local job_hud_state = job.hud_icon .. "/" .. i .. "/" .. job.hud_text
		if job.hud_state ~= job_hud_state then
			-- hud state updated
			player:hud_change(job[HUD_ICON_KEY], "text", job.hud_icon)
			player:hud_change(job[HUD_TEXT_KEY], "text", "[" .. i .. "] " .. job.hud_text)

			job.hud_state = job_hud_state
		end
	end
end


-- state tracking

local function create_hud(player)
	local player_settings = blockexchange.get_player_settings(player:get_player_name())
	if not player_settings.hud then
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

	local player_settings = blockexchange.get_player_settings(playername)
	player_settings.hud = enabled
	blockexchange.set_player_settings(playername, player_settings)

	if enabled then
		create_hud(player)
		return true, "Hud enabled"
	else
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
