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
local function main_fs(title, playername)
	local area = blockexchange.select_player_area(playername)

	local fs = ui.formspec(width, height) ..
		ui.button_exit(0,-1, 2.8,0.8, "show_main", "Info") ..
		ui.button_exit(3,-1, 2.8,0.8, "show_settings", "Player settings")

	if area then
		fs = fs .. ui.button_exit(6,-1, 2.8,0.8, "show_area", "Area")
	end

	fs = fs .. "label[1,1;" .. title .. "]"

	return fs
end

-- handle navigation
local function handle_top_nav(fields, playername)
	if fields.show_main then
		blockexchange.show_form_info(playername)
		return true
	elseif fields.show_settings then
		blockexchange.show_form_settings(playername)
		return true
	elseif fields.show_area then
		blockexchange.show_form_area(playername)
		return true
	else
		-- not a nav thing
		return false
	end
end

local function format_timestamp(ts)
	return os.date(nil, ts / 1000)
end

-- area specifics
function blockexchange.show_form_area(playername)
	local ctx = get_context(playername)
	ctx.form = "area"

	local area = blockexchange.select_player_area(playername)
	if not area then
		-- nothing to show
		return
	end

	local claims = blockexchange.get_claims(playername)
	local can_upload = claims and area.username == claims.username
	local is_owner = playername == area.playername

	return Promise.async(function(await)
		local schema, schema_err = await(blockexchange.api.get_schema_by_uid(area.schema_uid))
		local fs = main_fs("Area", playername)

		local secondary_color = "#BBBBBB"
		fs = fs .. "label[1,2;Local area info:]"
		fs = fs .. "label[1.2,2.5;Local ID: " .. minetest.colorize(secondary_color, area.id) .. "]"
		fs = fs .. "label[1.2,3;Name: " .. minetest.colorize(secondary_color, area.name)  .. "]"
		fs = fs .. "label[1.2,3.5;Owner: " .. minetest.colorize(secondary_color, area.playername)  .. "]"
		fs = fs .. "label[1.2,4;Modification time: " ..
			minetest.colorize(secondary_color, format_timestamp(area.mtime))  .. "]"

		if schema then
			fs = fs .. "label[1,5;" .. "Remote schematic:]"
			fs = fs .. "label[1.2,5.5;Remote ID: " .. minetest.colorize(secondary_color, schema.uid) .. "]"
			fs = fs .. "label[1.2,6;Name: " .. minetest.colorize(secondary_color, schema.name) .. "]"
			fs = fs .. "label[1.2,6.5;Modification time: " ..
				minetest.colorize(secondary_color, format_timestamp(schema.mtime)) .. "]"

			if not area.dirty and schema.mtime == area.mtime then
				-- no local changes and up to date
				fs = fs .. "label[1.2,7;" ..
					minetest.colorize("#00ff00", "Schematic up-to-date") ..
					"]"
			elseif is_owner and schema.mtime > area.mtime then
				-- remote schematic is newer, show update button
				fs = fs .. ui.button_exit(1,7, 4,0.8, "area_download", "Download updates")
			elseif is_owner and can_upload and area.dirty then
				-- local changes
				fs = fs .. ui.button_exit(1,7, 4,0.8, "area_upload", "Upload schematic")
			end

			if can_upload and is_owner then
				-- we could upload, show autosave option
				if area.autosave then
					fs = fs .. ui.checkbox_on(1,8,"toggle_autosave")
				else
					fs = fs .. ui.checkbox_off(1,8,"toggle_autosave")
				end
				fs = fs .. "label[2,8.3;Enable autosave on changes]"
			end

		else
			fs = fs .. "label[1,5;" ..
				minetest.colorize("#ffff00", "could not fetch remote schematic: " .. (schema_err or "<unknown error>")) ..
				"]"
		end

		local fields = await(Promise.formspec(playername, fs))
		if handle_top_nav(fields, playername) then
			return
		end

		if fields.toggle_autosave then
			area.autosave = not area.autosave
			blockexchange.save_areas()

			blockexchange.show_form_area(playername)
		elseif is_owner and fields.area_download then
			await(blockexchange.load_update_area(playername, area))
			blockexchange.show_form_area(playername)
		elseif is_owner and can_upload and fields.area_upload then
			await(blockexchange.save_update_area(playername,
				area.pos1, area.pos2,
				area.pos1, area.pos2,
				area.schema_uid
			))
			area.dirty = false
			blockexchange.save_areas()
			blockexchange.show_form_area(playername)
		end
	end)
end

-- user settings
function blockexchange.show_form_settings(playername)
	local player_settings = blockexchange.get_player_settings(playername)
	local ctx = get_context(playername)
	ctx.form = "settings"

	local fs = main_fs("Player settings", playername)

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
		local fs = main_fs("Info", playername)

		-- fetch remote info
		local info, err = await(cached_get_info())
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
	local area = blockexchange.select_player_area(playername)

	if ctx.form == "settings" then
		-- settings page
		return blockexchange.show_form_settings(playername)
	elseif ctx.form == "area" and area then
		-- area page
		return blockexchange.show_form_area(playername)
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
