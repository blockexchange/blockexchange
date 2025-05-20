local ui = blockexchange.ui

-- playername -> context
local context_data = {}

local function get_context(playername)
	local ctx = context_data[playername]
	if not ctx then
		-- new context
		ctx = {}
		context_data[playername] = ctx
	end
	return ctx
end

-- main formspec dimensions
local width, height = 10, 10
local function main_fs(title)
	return ui.formspec(width, height) ..
		ui.button_exit(0,-1, 2.8,0.8, "show_main", "Info") ..
		ui.button_exit(3,-1, 2.8,0.8, "show_settings", "Settings") ..
		"label[1,1;" .. title .. "]"
end

-- handle navigation
local function handle_top_nav(fields, playername)
	if fields.show_main then
		blockexchange.show_form_info(playername)
		return true
	elseif fields.show_settings then
		blockexchange.show_form_settings(playername)
		return true
	else
		-- not a nav thing
		return false
	end
end

-- user settings
function blockexchange.show_form_settings(playername)
	local player_settings = blockexchange.get_player_settings(playername)
	local ctx = get_context(playername)
	ctx.form = "settings"

	local fs = main_fs("Settings")

	-- Hud setting
	if player_settings.hud then
		fs = fs .. ui.checkbox_on(1,3,"toggle_hud")
	else
		fs = fs .. ui.checkbox_off(1,3,"toggle_hud")
	end
	fs = fs .. "label[2,3.3;Enable Hud]"

	-- Area tracking
	if player_settings.area_tracking then
		fs = fs .. ui.checkbox_on(1,4,"toggle_area_tracking")
	else
		fs = fs .. ui.checkbox_off(1,4,"toggle_area_tracking")
	end
	fs = fs .. "label[2,4.3;Enable Area tracking (for schematic updates)]"

	Promise.formspec(playername, fs):next(function(fields)
		if handle_top_nav(fields, playername) then
			return
		end

		if fields.toggle_hud then
			player_settings.hud = not player_settings.hud
			blockexchange.set_player_settings(playername, player_settings)
			blockexchange.set_player_hud(playername, player_settings.hud)
			blockexchange.show_form_settings(playername)
		elseif fields.toggle_area_tracking then
			player_settings.area_tracking = not player_settings.area_tracking
			blockexchange.set_player_settings(playername, player_settings)
			blockexchange.show_form_settings(playername)
		end

	end)
end

-- cache remote info for an hour
local cached_get_info = Promise.cache(3600, blockexchange.api.get_info)

-- generic info form
function blockexchange.show_form_info(playername)
	local ctx = get_context(playername)
	ctx.form = "info"

	return Promise.async(function(await)
		local fs = main_fs("Info")

		-- fetch remote info
		local info, err = await(cached_get_info)
		if err then
			error("remote info fetch failed: " .. err, 0)
		end

		local secondary_color = "#BBBBBB"
		fs = fs .. "label[1,2;Connected Blockexchange:]"
		fs = fs .. "label[1.2,2.5;Name: " .. minetest.colorize(secondary_color, info.name) .. "]"
		fs = fs .. "label[1.2,3;URL: " .. minetest.colorize(secondary_color, info.base_url)  .. "]"
		fs = fs .. "label[1.2,3.5;Users: " .. minetest.colorize(secondary_color, info.stats.user_count)  .. "]"
		fs = fs .. "label[1.2,4;Schematics: " .. minetest.colorize(secondary_color, info.stats.schema_count)  .. "]"

		local claims = blockexchange.get_claims(playername)
		if claims then
			fs = fs .. "label[1,5;" .. "Logged in:]"
			fs = fs .. "label[1.2,5.5;Name: " .. minetest.colorize(secondary_color, claims.username) .. "]"
			fs = fs .. "label[1.2,6;Type: " .. minetest.colorize(secondary_color, claims.type) .. "]"
			fs = fs .. "label[1.2,6.5;ID: " .. minetest.colorize(secondary_color, claims.user_uid) .. "]"
		else
			fs = fs .. "label[1,5;" .. minetest.colorize("#ffff00", "Not logged in") .. "]"
		end

		local fields = await(Promise.formspec(playername, fs))
		if handle_top_nav(fields, playername) then
			-- top nav change, return early
			return
		end
	end)
end

function blockexchange.show_form(playername)
	local ctx = get_context(playername)
	if ctx.form == "settings" then
		-- settings page
		return blockexchange.show_form_settings(playername)
	else
		-- default to info form
		return blockexchange.show_form_info(playername)
	end
end


Promise.register_chatcommand("bx", {
	description = "Shows the main blockexchange menu",
	func = blockexchange.show_form,
	handle_success = false
})
