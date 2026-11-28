---------
-- /bx_sync user interface: start page, upload/download wizards, status page, pull dialog and region list
--
-- all actions are exit-buttons (Promise.formspec resolves on "quit"), action buttons are prefixed with "btn_",
-- a "quit" without action button (escape key) cancels the current dialog.

local ui = blockexchange.ui
local sync = blockexchange.sync
local esc = core.formspec_escape

local sync_ui = {}
blockexchange.sync_ui = sync_ui

local W, H = 12, 9.5
local COLOR_OK = "#00ff00"
local COLOR_ERR = "#ff4444"
local COLOR_WARN = "#ffff00"
local COLOR_DIM = "#bbbbbb"

---------
-- formspec helpers

local function label(x, y, text, color)
	text = esc(text)
	if color then
		text = core.colorize(color, text)
	end
	return "label[" .. x .. "," .. y .. ";" .. text .. "]"
end

local function check_label(x, y, ok, text)
	return label(x, y, (ok and "[ok] " or "[x] ") .. text, ok and COLOR_OK or COLOR_ERR)
end

local function radio(x, y, selected, name, text)
	return (selected and ui.checkbox_on(x, y, name) or ui.checkbox_off(x, y, name)) ..
		label(x + 0.8, y + 0.3, text)
end

local function field(x, y, w, name, caption, value)
	return "field[" .. x .. "," .. y .. ";" .. w .. ",0.8;" .. name .. ";" .. esc(caption) .. ";" ..
		esc(value or "") .. "]"
end

local function frame(title, subtitle)
	local fs = ui.formspec(W, H) .. label(0.5, 0.6, title)
	if subtitle then
		fs = fs .. label(W - 3, 0.6, subtitle, COLOR_DIM)
	end
	return fs
end

local function pos_str(pos)
	return pos and core.pos_to_string(pos) or "<not set>"
end

local function size_str(pos1, pos2)
	local size = vector.add(vector.subtract(pos2, pos1), 1)
	return size.x .. "x" .. size.y .. "x" .. size.z
end

local function count_parts(pos1, pos2)
	local size = vector.add(vector.subtract(pos2, pos1), 1)
	return math.ceil(size.x / 16) * math.ceil(size.y / 16) * math.ceil(size.z / 16)
end

local function format_time(mtime)
	return mtime and mtime > 0 and os.date("%Y-%m-%d %H:%M", mtime / 1000) or "-"
end

-- returns true if the fields contain an action (button or enter key), false for escape
local function has_action(fields)
	for key in pairs(fields) do
		if key:sub(1, 4) == "btn_" or key == "key_enter" then
			return true
		end
	end
	return false
end

-- returns the index of the first "btn_<prefix>_<n>" field
local function get_indexed_button(fields, prefix)
	for key in pairs(fields) do
		local n = key:match("^btn_" .. prefix .. "_(%d+)$")
		if n then
			return tonumber(n)
		end
	end
end

local function overlap_error(pos1, pos2)
	local list = sync.get_in_area(pos1, pos2)
	if #list > 0 then
		return "overlaps synced region '" .. list[1].id .. "' (" .. (list[1].schema_name or list[1].schema_uid) .. ")"
	end
end

--- shows a message dialog
-- @return a promise resolving when the dialog is closed
function sync_ui.show_message(playername, title, text, color)
	local fs = frame(title) ..
		"textarea[0.5,1.5;" .. (W - 1) .. "," .. (H - 3.5) .. ";;;" ..
		esc(color and core.colorize(color, text) or text) .. "]" ..
		ui.button_exit(W - 3.3, H - 1.1, 2.8, 0.8, "btn_close", "Close")
	return Promise.formspec(playername, fs)
end

--- shows a confirmation dialog
-- @param buttons list of { name = "btn_x", label = "X" }, the dialog has a cancel button by default
-- @return a promise resolving with the name of the pressed button or nil if canceled
local function confirm(playername, title, text, buttons)
	local fs = frame(title) ..
		"textarea[0.5,1.5;" .. (W - 1) .. "," .. (H - 3.5) .. ";;;" .. esc(text) .. "]" ..
		ui.button_exit(0.5, H - 1.1, 2.8, 0.8, "btn_cancel", "Cancel")
	local x = W - 3.3
	for i = #buttons, 1, -1 do
		fs = fs .. ui.button_exit(x, H - 1.1, 2.8, 0.8, buttons[i].name, buttons[i].label)
		x = x - 3
	end
	return Promise.formspec(playername, fs):next(function(fields)
		for _, button in ipairs(buttons) do
			if fields[button.name] then
				return button.name
			end
		end
	end)
end

---------
-- wizard runner

--- runs a wizard
-- wizard: { title, steps = { step, ... }, finish_label }
-- step: {
--   title,
--   inputs = { "fieldname", ... },              -- text fields stored in ctx on every submit
--   render(ctx, playername) -> formspec body,
--   can_next(ctx, playername) -> boolean,      -- optional, next button disabled if false
--   on_next(ctx, playername, await) -> err,    -- optional, validation/action, stays on the step on error
--   handle(ctx, fields, playername, await),    -- optional, handles step specific buttons (re-renders afterwards)
--   next_label                                 -- optional label of the next button
-- }
-- @return a promise resolving with the ctx when finished or nil if canceled
function sync_ui.run_wizard(playername, wizard, ctx)
	ctx = ctx or {}
	ctx.step = ctx.step or 1

	return Promise.async(function(await)
		while true do
			local step = wizard.steps[ctx.step]
			local can_next = not step.can_next or step.can_next(ctx, playername)

			local fs = frame(wizard.title .. ": " .. step.title, "Step " .. ctx.step .. "/" .. #wizard.steps) ..
				step.render(ctx, playername)
			if ctx.error then
				fs = fs .. label(0.5, H - 1.6, ctx.error, COLOR_ERR)
			end
			fs = fs .. ui.button_exit(0.5, H - 1.1, 2.8, 0.8, "btn_cancel", "Cancel")
			if ctx.step > 1 then
				fs = fs .. ui.button_exit(W - 6.3, H - 1.1, 2.8, 0.8, "btn_back", "Back")
			end
			if can_next then
				local next_label = step.next_label or (ctx.step == #wizard.steps and "Finish" or "Next")
				fs = fs .. ui.button_exit(W - 3.3, H - 1.1, 2.8, 0.8, "btn_next", next_label)
			end

			local fields = await(Promise.formspec(playername, fs))
			for _, name in ipairs(step.inputs or {}) do
				if fields[name] then
					ctx[name] = fields[name]
				end
			end
			ctx.error = nil

			if fields.btn_cancel or not has_action(fields) then
				return nil
			elseif fields.btn_back then
				ctx.step = math.max(1, ctx.step - 1)
			elseif fields.btn_next or fields.key_enter then
				-- inputs may have changed the preconditions
				if not step.can_next or step.can_next(ctx, playername) then
					local err = step.on_next and step.on_next(ctx, playername, await)
					if err then
						ctx.error = err
					elseif ctx.step == #wizard.steps then
						return ctx
					else
						ctx.step = ctx.step + 1
					end
				end
			elseif step.handle then
				step.handle(ctx, fields, playername, await)
			end
		end
	end)
end

---------
-- upload wizard

local function upload_checks(ctx, playername)
	ctx.pos1 = blockexchange.get_pos(1, playername)
	ctx.pos2 = blockexchange.get_pos(2, playername)
	if ctx.pos1 and ctx.pos2 then
		ctx.pos1, ctx.pos2 = blockexchange.sort_pos(ctx.pos1, ctx.pos2)
	end

	local claims = blockexchange.get_claims(playername)
	local has_privs = core.check_player_privs(playername, { blockexchange = true }) or
		core.check_player_privs(playername, { blockexchange_protected_upload = true })

	local checks = {
		{ ok = claims ~= nil, text = claims and ("logged in as '" .. claims.username .. "'") or "not logged in" },
		{ ok = has_privs, text = "privilege 'blockexchange' or 'blockexchange_protected_upload'" },
		{ ok = ctx.pos1 ~= nil and ctx.pos2 ~= nil, text = "positions set (/bx_pos1, /bx_pos2)" }
	}
	if ctx.pos1 and ctx.pos2 then
		table.insert(checks, {
			ok = blockexchange.check_size(ctx.pos1, ctx.pos2),
			text = "axis size limit of " .. blockexchange.max_size .. " nodes"
		})
		local overlap = overlap_error(ctx.pos1, ctx.pos2)
		table.insert(checks, { ok = not overlap, text = overlap or "no overlap with synced regions" })
	end
	return checks, claims
end

local function all_ok(checks)
	for _, check in ipairs(checks) do
		if not check.ok then
			return false
		end
	end
	return true
end

local upload_wizard = {
	title = "Upload",
	steps = {
		{
			title = "Selection",
			render = function(ctx, playername)
				local checks = upload_checks(ctx, playername)
				local fs = label(0.5, 1.6, "Position 1: " .. pos_str(ctx.pos1)) ..
					label(0.5, 2.1, "Position 2: " .. pos_str(ctx.pos2))
				if ctx.pos1 and ctx.pos2 then
					fs = fs .. label(0.5, 2.6, "Size: " .. size_str(ctx.pos1, ctx.pos2) ..
						", " .. count_parts(ctx.pos1, ctx.pos2) .. " parts")
				end
				for i, check in ipairs(checks) do
					fs = fs .. check_label(0.5, 3.1 + i * 0.5, check.ok, check.text)
				end
				return fs .. ui.button_exit(W - 4.3, 1.3, 3.8, 0.8, "btn_refresh", "Refresh selection")
			end,
			can_next = function(ctx, playername)
				return all_ok(upload_checks(ctx, playername))
			end,
			on_next = function(ctx, playername, await)
				local needs_protection_check =
					not core.check_player_privs(playername, { blockexchange = true }) and
					not core.check_player_privs(playername, { protection_bypass = true })
				if needs_protection_check then
					local result, err = await(blockexchange.protectioncheck(playername, ctx.pos1, ctx.pos2))
					if err then
						return "protection check error: " .. err
					elseif not result.success then
						return "protected area between " .. core.pos_to_string(result.pos1) ..
							" and " .. core.pos_to_string(result.pos2)
					end
				end
			end,
			handle = function() end -- refresh: re-render
		},
		{
			title = "Target",
			inputs = { "schemaname" },
			render = function(ctx)
				local fs = radio(0.5, 1.3, ctx.target ~= "existing", "btn_target_new", "New schematic") ..
					radio(0.5, 3.6, ctx.target == "existing", "btn_target_existing",
						"Existing schematic of the same size (local state takes precedence)")
				if ctx.target ~= "existing" then
					fs = fs .. field(1.3, 2.4, 6, "schemaname", "Name", ctx.schemaname)
				else
					local list = ctx.existing_list or {}
					if #list == 0 then
						fs = fs .. label(1.3, 4.6, "No schematics of the same size found", COLOR_WARN)
					end
					for i, result in ipairs(list) do
						fs = fs .. radio(1.3, 4.2 + (i - 1) * 0.6, ctx.existing_index == i, "btn_existing_" .. i,
							result.schema.name .. " (" .. format_time(result.schema.mtime) .. ")")
					end
				end
				return fs
			end,
			can_next = function(ctx)
				return ctx.target ~= "existing" or ctx.existing_index ~= nil
			end,
			on_next = function(ctx, playername, await)
				if ctx.target == "existing" then
					return
				end
				local name = ctx.schemaname or ""
				if name == "" then
					return "please enter a name"
				elseif not blockexchange.validate_name(name) then
					return "the name can only contain letters, numbers and - _ ."
				end
				local claims = blockexchange.get_claims(playername)
				local result, err = await(blockexchange.api.search_schemas({
					user_name = claims.username,
					schema_name = name
				}))
				if err then
					return "search error: " .. err
				elseif #result > 0 then
					return "you already have a schematic named '" .. name .. "'"
				end
			end,
			handle = function(ctx, fields, playername, await)
				if fields.btn_target_new then
					ctx.target = "new"
				elseif fields.btn_target_existing then
					ctx.target = "existing"
					ctx.existing_index = nil
					local claims = blockexchange.get_claims(playername)
					local result, err = await(blockexchange.api.search_schemas({
						user_uid = claims.user_uid,
						limit = 100
					}))
					if err then
						ctx.error = "search error: " .. err
						result = {}
					end
					local size = vector.add(vector.subtract(ctx.pos2, ctx.pos1), 1)
					ctx.existing_list = {}
					for _, entry in ipairs(result) do
						local s = entry.schema
						if s.size_x == size.x and s.size_y == size.y and s.size_z == size.z and #ctx.existing_list < 7 then
							table.insert(ctx.existing_list, entry)
						end
					end
				else
					ctx.existing_index = get_indexed_button(fields, "existing") or ctx.existing_index
				end
			end
		},
		{
			title = "Options",
			render = function(ctx)
				local fs = ""
				if ctx.target == "existing" then
					fs = fs .. label(0.5, 1.6, "The region is synced with the existing schematic")
				else
					fs = fs .. radio(0.5, 1.3, ctx.keep_synced, "btn_toggle_synced",
						"Keep synced (track local changes and pull remote updates)")
				end
				if ctx.target == "existing" or ctx.keep_synced then
					fs = fs .. radio(0.5, 2.3, ctx.autosave, "btn_toggle_autosave", "Upload changes automatically (autosave)")
				end
				return fs
			end,
			handle = function(ctx, fields)
				if fields.btn_toggle_synced then
					ctx.keep_synced = not ctx.keep_synced
				elseif fields.btn_toggle_autosave then
					ctx.autosave = not ctx.autosave
				end
			end
		},
		{
			title = "Confirm",
			next_label = "Upload",
			render = function(ctx)
				local synced = ctx.target == "existing" or ctx.keep_synced
				local target
				if ctx.target == "existing" then
					target = "existing schematic '" .. ctx.existing_list[ctx.existing_index].schema.name .. "'"
				else
					target = "new schematic '" .. ctx.schemaname .. "'"
				end
				return label(0.5, 1.6, "Area: " .. pos_str(ctx.pos1) .. " - " .. pos_str(ctx.pos2) ..
						" (" .. size_str(ctx.pos1, ctx.pos2) .. ")") ..
					label(0.5, 2.1, "Target: " .. target) ..
					label(0.5, 2.6, "Synced: " .. (synced and "yes" or "no") ..
						(synced and (", autosave: " .. (ctx.autosave and "on" or "off")) or ""))
			end,
			on_next = function(ctx, playername, await)
				local claims = blockexchange.get_claims(playername)
				local result, err
				if ctx.target == "existing" then
					local found = ctx.existing_list[ctx.existing_index]
					-- autosave gets enabled after the initial push
					local entry
					entry, err = await(sync.link(playername, ctx.pos1, found.schema.uid, { owner = claims.username }))
					if err then
						return "link error: " .. err
					end
					result, err = await(sync.push(playername, entry))
					if err then
						return "push error: " .. err
					end
					entry.autosave = ctx.autosave
					sync.save()
					ctx.entry = entry
					ctx.result_text = "Synced with '" .. found.schema.name .. "', uploaded " ..
						result.nodes .. " changed nodes in " .. result.parts .. " parts"
				elseif ctx.keep_synced then
					result, err = await(sync.upload(playername, ctx.pos1, ctx.pos2, ctx.schemaname, { autosave = ctx.autosave }))
					if err then
						return "upload error: " .. err
					end
					ctx.entry = result.entry
					ctx.result_text = "Uploaded '" .. ctx.schemaname .. "' with " .. result.total_parts ..
						" parts, synced region: " .. result.entry.id
				else
					result, err = await(blockexchange.save(playername, ctx.pos1, ctx.pos2, ctx.schemaname))
					if err then
						return "upload error: " .. err
					end
					ctx.result_text = "Uploaded '" .. ctx.schemaname .. "' with " .. result.total_parts .. " parts"
				end
				ctx.result_text = ctx.result_text .. "\n\n" .. blockexchange.url .. "/#/schema/" ..
					claims.username .. "/" .. (ctx.schemaname or ctx.existing_list[ctx.existing_index].schema.name)
			end
		}
	}
}

--- starts the upload wizard
-- @return a promise resolving with the wizard ctx when finished or nil if canceled
function sync_ui.show_upload(playername)
	return sync_ui.run_wizard(playername, upload_wizard, {
		target = "new",
		keep_synced = true,
		autosave = true
	}):next(function(ctx)
		if ctx then
			return sync_ui.show_message(playername, "Upload complete", ctx.result_text):next(function()
				return ctx
			end)
		end
	end)
end

---------
-- download wizard

local function parse_source(source)
	source = (source or ""):trim()
	if source:match("^%x+%-%x+%-%x+%-%x+%-%x+$") then
		return { schema_uid = source }
	end
	local user_name, schema_name = source:match("^([^/%s]+)/([^/%s]+)$")
	if user_name then
		return { user_name = user_name, schema_name = schema_name }
	end
end

local function get_missing_mods(mods)
	local missing = {}
	for _, modname in ipairs(mods or {}) do
		if not core.get_modpath(modname) then
			table.insert(missing, modname)
		end
	end
	return missing
end

local function update_placement(ctx, playername)
	if ctx.placement == "player" then
		local player = core.get_player_by_name(playername)
		ctx.pos1 = player and vector.round(player:get_pos())
	else
		ctx.pos1 = blockexchange.get_pos(1, playername)
	end
	ctx.pos2 = ctx.pos1 and blockexchange.get_schema_pos2(ctx.pos1, ctx.found.schema)
end

local download_wizard = {
	title = "Download",
	steps = {
		{
			title = "Source",
			inputs = { "source" },
			render = function(ctx, playername)
				local fs = field(0.5, 2, W - 1, "source", "Schematic: <username>/<schematic name> or schematic UID",
						ctx.source) ..
					label(0.5, 3.4, "Example: someuser/my_house", COLOR_DIM)
				if not core.check_player_privs(playername, { blockexchange = true }) then
					fs = fs .. check_label(0.5, 4.2, false, "privilege 'blockexchange' required")
				end
				return fs
			end,
			can_next = function(_, playername)
				return core.check_player_privs(playername, { blockexchange = true })
			end,
			on_next = function(ctx, _, await)
				local query = parse_source(ctx.source)
				if not query then
					return "invalid input, expected <username>/<schematic name> or a schematic UID"
				end
				local result, err = await(blockexchange.api.search_schemas(query))
				if err then
					return "search error: " .. err
				elseif #result == 0 then
					return "schematic not found"
				end
				ctx.found = result[1]
				ctx.missing_mods = get_missing_mods(ctx.found.mods)
			end
		},
		{
			title = "Placement",
			render = function(ctx, playername)
				update_placement(ctx, playername)
				local schema = ctx.found.schema
				local fs = label(0.5, 1.6, "Schematic: " .. ctx.found.username .. "/" .. schema.name) ..
					label(0.5, 2.1, "Size: " .. schema.size_x .. "x" .. schema.size_y .. "x" .. schema.size_z ..
						", license: " .. (schema.license or "?") .. ", modified: " .. format_time(schema.mtime))
				if #ctx.missing_mods > 0 then
					fs = fs .. label(0.5, 2.6, "Missing mods: " .. table.concat(ctx.missing_mods, ", "), COLOR_WARN)
				end
				fs = fs .. radio(0.5, 3.2, ctx.placement ~= "player", "btn_place_pos1", "At position 1 (/bx_pos1)") ..
					radio(0.5, 3.9, ctx.placement == "player", "btn_place_player", "At my position") ..
					label(0.5, 5, "Target: " .. pos_str(ctx.pos1) .. " - " .. pos_str(ctx.pos2))

				if ctx.pos1 then
					local overlap = overlap_error(ctx.pos1, ctx.pos2)
					if overlap then
						fs = fs .. label(0.5, 5.5, "Warning: " .. overlap, COLOR_WARN)
					end
					if ctx.protected then
						fs = fs .. check_label(0.5, 6, false, "the target area is protected")
					end
				end
				return fs
			end,
			can_next = function(ctx, playername)
				update_placement(ctx, playername)
				return ctx.pos1 ~= nil
			end,
			on_next = function(ctx, playername)
				ctx.protected = not core.check_player_privs(playername, { protection_bypass = true }) and
					blockexchange.is_area_protected(ctx.pos1, ctx.pos2, playername)
				if ctx.protected then
					return "the target area is protected"
				end
			end,
			handle = function(ctx, fields)
				if fields.btn_place_pos1 then
					ctx.placement = "pos1"
				elseif fields.btn_place_player then
					ctx.placement = "player"
				end
				ctx.protected = nil
			end
		},
		{
			title = "Mode",
			render = function(ctx, playername)
				local can_write = sync.can_write(playername, { owner_uid = ctx.found.schema.user_uid })
				local fs = radio(0.5, 1.3, ctx.mode == "copy", "btn_mode_copy", "One-off copy (no sync)") ..
					radio(0.5, 2.1, ctx.mode == "ro", "btn_mode_ro", "Synced, read-only (follow remote updates)")
				if can_write then
					fs = fs .. radio(0.5, 2.9, ctx.mode == "rw", "btn_mode_rw", "Synced, read-write (you own this schematic)")
					if ctx.mode == "rw" then
						fs = fs .. radio(1.3, 3.7, ctx.autosave, "btn_toggle_autosave", "Upload changes automatically (autosave)")
					end
				end
				if ctx.mode ~= "copy" then
					local overlap = overlap_error(ctx.pos1, ctx.pos2)
					if overlap then
						fs = fs .. label(0.5, 5, "Synced download not possible: " .. overlap, COLOR_ERR)
					end
				end
				return fs
			end,
			can_next = function(ctx)
				return ctx.mode == "copy" or not overlap_error(ctx.pos1, ctx.pos2)
			end,
			handle = function(ctx, fields)
				if fields.btn_mode_copy then
					ctx.mode = "copy"
				elseif fields.btn_mode_ro then
					ctx.mode = "ro"
				elseif fields.btn_mode_rw then
					ctx.mode = "rw"
				elseif fields.btn_toggle_autosave then
					ctx.autosave = not ctx.autosave
				end
			end
		},
		{
			title = "Confirm",
			next_label = "Download",
			render = function(ctx)
				local modes = { copy = "one-off copy", ro = "synced, read-only", rw = "synced, read-write" }
				return label(0.5, 1.6, "Schematic: " .. ctx.found.username .. "/" .. ctx.found.schema.name) ..
					label(0.5, 2.1, "Target: " .. pos_str(ctx.pos1) .. " - " .. pos_str(ctx.pos2)) ..
					label(0.5, 2.6, "Mode: " .. modes[ctx.mode] ..
						(ctx.mode == "rw" and (", autosave: " .. (ctx.autosave and "on" or "off")) or "")) ..
					label(0.5, 3.4, "Existing builds in the target area will be overwritten!", COLOR_WARN)
			end,
			on_next = function(ctx, playername, await)
				local _, err = await(blockexchange.emerge(playername, ctx.pos1, ctx.pos2))
				if err then
					return "emerge error: " .. err
				end

				local result
				local schema = ctx.found.schema
				if ctx.mode == "copy" then
					result, err = await(blockexchange.load_by_uid(playername, ctx.pos1, schema.uid))
					if err then
						return "download error: " .. err
					end
					ctx.result_text = "Downloaded '" .. schema.name .. "' with " .. result.total_parts .. " parts"
				else
					result, err = await(sync.download(playername, ctx.pos1, schema.uid, {
						owner = ctx.found.username,
						autosave = ctx.mode == "rw" and ctx.autosave
					}))
					if err then
						return "download error: " .. err
					end
					ctx.entry = result.entry
					ctx.result_text = "Downloaded '" .. schema.name .. "' with " .. result.total_parts ..
						" parts, synced region: " .. result.entry.id
				end
			end
		}
	}
}

--- starts the download wizard
-- @return a promise resolving with the wizard ctx when finished or nil if canceled
function sync_ui.show_download(playername)
	return sync_ui.run_wizard(playername, download_wizard, {
		placement = "pos1",
		mode = "ro",
		autosave = true
	}):next(function(ctx)
		if ctx then
			return sync_ui.show_message(playername, "Download complete", ctx.result_text):next(function()
				return ctx
			end)
		end
	end)
end

---------
-- pull dialog

-- runs the pull flow (fetch, summary dialog, apply)
-- @return a promise resolving with a message
local function pull_flow(playername, entry, await)
	local plan, err = await(sync.fetch(entry))
	if err then
		error("fetch error: " .. err, 0)
	end

	if #plan.parts == 0 then
		await(sync.apply(playername, plan, "abort"))
		return "Already up to date"
	end

	local analysis = sync.analyze(plan)
	local policy = "mine"
	while true do
		local fs = frame("Pull: " .. (entry.schema_name or entry.schema_uid)) ..
			label(0.5, 1.6, analysis.parts .. " remote parts newer than your copy") ..
			label(1, 2.1, analysis.changed_parts .. " parts with " .. analysis.remote_nodes .. " changed nodes to apply") ..
			label(1, 2.6, analysis.conflict_parts .. " parts with " .. analysis.conflicts .. " conflicting nodes",
				analysis.conflicts > 0 and COLOR_WARN or nil)
		if analysis.conflicts > 0 then
			fs = fs .. label(0.5, 3.5, "Nodes changed on both sides:") ..
				radio(0.5, 3.9, policy == "mine", "btn_policy_mine", "Keep mine") ..
				radio(4.5, 3.9, policy == "theirs", "btn_policy_theirs", "Take remote")
		end
		fs = fs .. ui.button_exit(0.5, H - 1.1, 2.8, 0.8, "btn_cancel", "Cancel") ..
			ui.button_exit(W - 3.3, H - 1.1, 2.8, 0.8, "btn_apply", "Apply")

		local fields = await(Promise.formspec(playername, fs))
		if fields.btn_policy_mine then
			policy = "mine"
		elseif fields.btn_policy_theirs then
			policy = "theirs"
		elseif fields.btn_apply then
			break
		else
			return "Pull canceled"
		end
	end

	local stats
	stats, err = await(sync.apply(playername, plan, policy))
	if err then
		error("pull error: " .. err, 0)
	end
	return "Pulled " .. stats.remote_nodes .. " nodes in " .. stats.parts .. " parts" ..
		(stats.conflicts > 0 and (", " .. stats.conflicts .. " conflicts resolved (" .. policy .. ")") or "")
end

-- runs the push flow (warning if remote is newer)
-- @return a promise resolving with a message
local function push_flow(playername, entry, remote_newer, await)
	if remote_newer and remote_newer > 0 then
		local choice = await(confirm(playername, "Push: " .. (entry.schema_name or entry.schema_uid),
			"The remote schematic has " .. remote_newer .. " newer parts.\n" ..
			"Nodes changed on both sides will be overwritten with your version.\n\n" ..
			"Pulling first is recommended.",
			{ { name = "btn_pull", label = "Pull first" }, { name = "btn_push", label = "Push anyway" } }))
		if choice == "btn_pull" then
			return pull_flow(playername, entry, await)
		elseif choice ~= "btn_push" then
			return "Push canceled"
		end
	end

	local stats, err = await(sync.push(playername, entry))
	if err then
		error("push error: " .. err, 0)
	end
	return "Pushed " .. stats.nodes .. " changed nodes in " .. stats.parts .. " parts"
end

---------
-- status page

-- fetches the remote state of the entry
-- @return { info = "...", color = "#...", newer = <number of newer remote parts or nil> }
local function fetch_remote_state(await, entry)
	local schema, err = await(blockexchange.api.get_schema_by_uid(entry.schema_uid))
	if err or not schema then
		return { info = "could not fetch remote schematic: " .. (err or "not found"), color = COLOR_ERR }
	end
	if not entry.owner_uid then
		-- migrated regions only know the owner name
		entry.owner_uid = schema.user_uid
		entry.schema_name = schema.name
		sync.save()
	end
	local newer = await(blockexchange.api.count_next_schemapart_by_mtime(entry.schema_uid, entry.pulled_mtime))
	if newer and newer > 0 then
		return { info = newer .. " parts newer (" .. format_time(schema.mtime) .. ")", color = COLOR_WARN, newer = newer }
	end
	return { info = "up to date (" .. format_time(schema.mtime) .. ")", color = COLOR_OK, newer = 0 }
end

-- returns the permissions of the player for the entry
local function get_status_permissions(playername, entry)
	return {
		can_write = sync.can_write(playername, entry),
		can_pull = core.check_player_privs(playername, { blockexchange = true }),
		busy = sync.get_busy(entry)
	}
end

local function render_action_buttons(entry, perm)
	local fs = ""
	if entry.state == "needs_baseline" then
		fs = fs .. label(0.5, 3.6, "This region has no sync baseline (migrated area), choose the authoritative side:",
			COLOR_WARN)
		if perm.can_pull then
			fs = fs .. ui.button_exit(0.5, 4.2, 5.3, 0.8, "btn_remote_wins", "Remote wins (download)")
		end
		if perm.can_write then
			fs = fs .. ui.button_exit(6.2, 4.2, 5.3, 0.8, "btn_local_wins", "Local wins (upload)")
		end
	elseif not perm.busy then
		if perm.can_pull then
			fs = fs .. ui.button_exit(0.5, 3.8, 2.8, 0.8, "btn_pull", "Pull...")
		end
		if perm.can_write then
			fs = fs .. ui.button_exit(3.5, 3.8, 2.8, 0.8, "btn_push", "Push") ..
				radio(0.5, 5, entry.autosave, "btn_toggle_autosave", "Upload changes automatically (autosave)")
		end
	end
	return fs
end

local function render_status(entry, perm, remote, message)
	local dirty_count = sync.count_dirty(entry)
	local fs = frame("Sync: " .. (entry.owner or "?") .. "/" .. (entry.schema_name or entry.schema_uid) ..
			" [" .. (perm.can_write and "rw" or "ro") .. "]", "ID: " .. entry.id) ..
		label(0.5, 1.6, "Region: " .. pos_str(entry.pos1) .. " - " .. pos_str(entry.pos2) ..
			" (" .. size_str(entry.pos1, entry.pos2) .. ")") ..
		label(0.5, 2.1, "Local: " .. (dirty_count > 0 and (dirty_count .. " parts changed") or "no changes"),
			dirty_count > 0 and COLOR_WARN or COLOR_OK) ..
		label(0.5, 2.6, "Remote: " .. remote.info, remote.color)
	if perm.busy then
		fs = fs .. label(0.5, 3.1, "Running: " .. perm.busy, COLOR_WARN)
	end
	if message then
		fs = fs .. label(0.5, H - 2.2, message, COLOR_DIM)
	end

	return fs .. render_action_buttons(entry, perm) ..
		ui.button_exit(0.5, 6.2, 3.3, 0.8, "btn_mark", "Mark region") ..
		ui.button_exit(4.1, 6.2, 3.3, 0.8, "btn_unlink", "Unlink...") ..
		ui.button_exit(7.7, 6.2, 3.8, 0.8, "btn_refresh", "Refresh") ..
		ui.button_exit(0.5, H - 1.1, 2.8, 0.8, "btn_list", "All regions") ..
		ui.button_exit(W - 3.3, H - 1.1, 2.8, 0.8, "btn_close", "Close")
end

-- returns the long running action (function(await) -> message) for the pressed button or nil
local function get_status_action(playername, entry, fields, perm, remote)
	local idle = not perm.busy
	if fields.btn_pull and perm.can_pull and idle then
		return function(aw) return pull_flow(playername, entry, aw) end
	elseif fields.btn_push and perm.can_write and idle then
		return function(aw) return push_flow(playername, entry, remote.newer, aw) end
	elseif fields.btn_remote_wins and perm.can_pull and idle then
		return function(aw)
			local _, e = aw(sync.resolve_remote(playername, entry))
			if e then error(e, 0) end
			return "Region downloaded again"
		end
	elseif fields.btn_local_wins and perm.can_write and idle then
		return function(aw)
			local _, e = aw(sync.resolve_local(entry))
			if e then error(e, 0) end
			return push_flow(playername, entry, 0, aw)
		end
	end
end

-- runs the action and returns the resulting message
local function run_status_action(await, playername, action)
	-- separate coroutine, errors are returned as rejection
	local result, err = await(Promise.async(action))
	if err then
		core.chat_send_player(playername, core.colorize(COLOR_ERR, "[blockexchange] " .. tostring(err)))
		return tostring(err)
	end
	core.chat_send_player(playername, "[blockexchange] " .. tostring(result))
	return tostring(result)
end

--- shows the status page of the synced region
function sync_ui.show_status(playername, entry, message)
	return Promise.async(function(await)
		while sync.get(entry.id) do
			local remote = fetch_remote_state(await, entry)
			local perm = get_status_permissions(playername, entry)
			local fields = await(Promise.formspec(playername, render_status(entry, perm, remote, message)))
			message = nil

			local action = get_status_action(playername, entry, fields, perm, remote)
			if action then
				message = run_status_action(await, playername, action)
			elseif fields.btn_toggle_autosave and perm.can_write then
				entry.autosave = not entry.autosave
				sync.save()
			elseif fields.btn_mark then
				blockexchange.set_pos(1, playername, entry.pos1)
				blockexchange.set_pos(2, playername, entry.pos2)
				return
			elseif fields.btn_unlink then
				local choice = await(confirm(playername, "Unlink region",
					"Remove the sync information of region '" .. entry.id .. "'?\n" ..
					"The build stays in the world, local changes are not uploaded anymore.",
					{ { name = "btn_unlink", label = "Unlink" } }))
				if choice == "btn_unlink" then
					sync.remove(entry.id)
					core.chat_send_player(playername, "[blockexchange] synced region '" .. entry.id .. "' unlinked")
					return
				end
			elseif fields.btn_list then
				return sync_ui.show_list(playername)
			elseif not fields.btn_refresh then
				-- close or escape
				return
			end
		end
	end)
end

---------
-- region list

local PAGE_SIZE = 8

--- shows the list of synced regions
function sync_ui.show_list(playername, page)
	page = page or 1
	return Promise.async(function(await)
		local list = sync.list()
		table.sort(list, function(a, b)
			return (a.schema_name or "") < (b.schema_name or "")
		end)
		local pages = math.max(1, math.ceil(#list / PAGE_SIZE))
		page = math.min(page, pages)

		local fs = frame("Synced regions", "Page " .. page .. "/" .. pages)
		if #list == 0 then
			fs = fs .. label(0.5, 1.6, "No synced regions yet")
		end
		local shown = {}
		for i = (page - 1) * PAGE_SIZE + 1, math.min(#list, page * PAGE_SIZE) do
			local entry = list[i]
			local row = #shown + 1
			local y = 1.2 + (row - 1) * 0.8
			local dirty_count = sync.count_dirty(entry)
			fs = fs .. label(0.5, y + 0.35, entry.id .. "  " .. (entry.owner or "?") .. "/" ..
					(entry.schema_name or entry.schema_uid) .. "  " .. pos_str(entry.pos1) ..
					(entry.autosave and "  [autosave]" or "") ..
					(dirty_count > 0 and ("  [" .. dirty_count .. " changed]") or "") ..
					(entry.state ~= "ok" and ("  [" .. entry.state .. "]") or "")) ..
				ui.button_exit(W - 2.5, y, 2, 0.7, "btn_status_" .. row, "Status")
			shown[row] = entry
		end
		if page > 1 then
			fs = fs .. ui.button_exit(W - 6.3, H - 1.1, 1.4, 0.8, "btn_prev", "<")
		end
		if page < pages then
			fs = fs .. ui.button_exit(W - 4.8, H - 1.1, 1.4, 0.8, "btn_next", ">")
		end
		fs = fs .. ui.button_exit(W - 3.3, H - 1.1, 2.8, 0.8, "btn_close", "Close")

		local fields = await(Promise.formspec(playername, fs))
		local row = get_indexed_button(fields, "status")
		if row and shown[row] then
			return sync_ui.show_status(playername, shown[row])
		elseif fields.btn_prev then
			return sync_ui.show_list(playername, page - 1)
		elseif fields.btn_next then
			return sync_ui.show_list(playername, page + 1)
		end
	end)
end

---------
-- start page

--- shows the start page (outside of synced regions)
function sync_ui.show_start(playername)
	local fs = frame("Blockexchange sync") ..
		label(0.5, 1.6, "You are not in a synced region.") ..
		ui.button_exit(0.5, 2.4, 5.3, 0.8, "btn_upload", "Upload selection") ..
		ui.button_exit(6.2, 2.4, 5.3, 0.8, "btn_download", "Download") ..
		ui.button_exit(0.5, 3.6, 5.3, 0.8, "btn_list", "Synced regions (" .. #sync.list() .. ")") ..
		ui.button_exit(W - 3.3, H - 1.1, 2.8, 0.8, "btn_close", "Close")

	return Promise.formspec(playername, fs):next(function(fields)
		if fields.btn_upload then
			return sync_ui.show_upload(playername)
		elseif fields.btn_download then
			return sync_ui.show_download(playername)
		elseif fields.btn_list then
			return sync_ui.show_list(playername)
		end
	end)
end

--- shows the status page of the synced region at the player position or the start page
function sync_ui.show(playername)
	local player = core.get_player_by_name(playername)
	local entry = player and sync.get_at(player:get_pos())
	if entry then
		return sync_ui.show_status(playername, entry)
	else
		return sync_ui.show_start(playername)
	end
end
