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
	local ctx = get_context(playername)
	ctx.form = "settings"

	local fs = main_fs("Settings")
	Promise.formspec(playername, fs):next(function(fields)
		if handle_top_nav(fields, playername) then
			return
		end
	end)
end

-- generic info form
function blockexchange.show_form_info(playername)
	local ctx = get_context(playername)
	ctx.form = "info"

	-- TODO: profile info if logged in / web link to blockexchange page
	-- TODO: logout button
	local fs = main_fs("Info")
	Promise.formspec(playername, fs):next(function(fields)
		if handle_top_nav(fields, playername) then
			return
		end
	end)
end

function blockexchange.show_form(playername)
	local ctx = get_context(playername)
	if ctx.form == "settings" then
		-- settings page
		blockexchange.show_form_settings(playername)
	else
		-- default to info form
		blockexchange.show_form_info(playername)
	end
end


minetest.register_chatcommand("bx", {
	description = "Shows the main blockexchange menu",
	func = blockexchange.show_form
})
