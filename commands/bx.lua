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


-- browser form
function blockexchange.show_form_browser(playername)
	local ctx = get_context(playername)
	ctx.form = "browser"
	-- TODO: get results from context
	local fs = [[
		size[10,10];
		input[search];
		button_exit[back];
		button_exit[show_detail;xy]
	]]
	Promise.formspec(playername, fs):next(function(fields)
		if fields.back then
			blockexchange.show_form_main(playername)
		elseif fields.show_detail then
			ctx.schema_uid = "x"
			blockexchange.show_form_schematic(playername)
		elseif fields.search then
			-- TODO: search schematics and store in ctx
			-- TODO: page / offset
		end
	end)
end

-- schematic detail form
function blockexchange.show_form_schematic(playername)
	local ctx = get_context(playername)
	ctx.form = "schematic"
	Promise.async(function(await)
		local err
		if not ctx.schema or ctx.schema.uid ~= ctx.schema_uid then
			-- fetch schema
			ctx.schema, err = await(blockexchange.api.get_schema_by_uid(ctx.schema_uid))
		end
		local fs
		if err then
			fs = [[
				size[10,10];
				button_exit[retry];
			]]
		else
			fs = [[
				size[10,10];
				button_exit[allocate];
				button_exit[load];
				button_exit[back];
			]]
		end
		Promise.formspec(playername, fs):next(function(fields)
			if fields.retry then
				blockexchange.show_form_schematic(playername)
			elseif fields.back then
				blockexchange.show_form_main(playername)
			end
		end)
	end)
end

-- user settings
function blockexchange.show_form_settings(playername)
	local fs = [[
		size[10,10];
		button_exit[back];
	]]
	Promise.formspec(playername, fs):next(function(fields)
		if fields.back then
			blockexchange.show_form_main(playername)
		end
	end)
end

-- user profile / logout
function blockexchange.show_form_profile(playername)
	local fs = [[
		size[10,10];
		button_exit[back];
	]]
	Promise.formspec(playername, fs):next(function(fields)
		if fields.back then
			blockexchange.show_form_main(playername)
		end
	end)
end

-- main entry
function blockexchange.show_form_main(playername)
	local ctx = get_context(playername)
	ctx.form = "main"
	local fs = ui.formspec(10,10) ..
		ui.button_exit(0,-1, 2.8,0.8, "show_settings", "Settings") ..
		ui.button_exit(3,-1, 2.8,0.8, "show_profile", "Profile")

	Promise.formspec(playername, fs):next(function(fields)
		if fields.show_settings then
			blockexchange.show_form_settings(playername)
		elseif fields.show_profile then
			blockexchange.show_form_profile(playername)
		end
	end)
end

function blockexchange.show_form(playername)
	local ctx = get_context(playername)
	if ctx.form == "schematic" then
		-- previous page is on schematic detail
		blockexchange.show_form_schematic(playername)
	elseif ctx.form == "browser" then
		-- previous page was schematic browser
		blockexchange.show_form_browser(playername)
	else
		-- default to main form
		blockexchange.show_form_main(playername)
	end
end


minetest.register_chatcommand("bx", {
	description = "Shows the main blockexchange menu",
	func = blockexchange.show_form
})
