---------
-- /bx_sync command
--
-- /bx_sync                                 opens the sync ui (status page in a synced region, start page otherwise)
-- /bx_sync status [id]                     shows the status of the synced region
-- /bx_sync list                            lists all synced regions
-- /bx_sync push [id]                       uploads the local changes
-- /bx_sync pull [mine|theirs] [id]         downloads and merges the remote changes (aborts on conflicts by default)
-- /bx_sync autosave <on|off> [id]          toggles the autosave of the region
-- /bx_sync unlink [id]                     removes the sync information (the build stays)

local sync = blockexchange.sync

local usage = "Usage: /bx_sync [status|list|push|pull [mine|theirs]|autosave <on|off>|unlink] [id]"

-- returns the entry with the given id or at the player position
local function select_entry(playername, id)
	if id and id ~= "" then
		local entry = sync.get(id)
		if not entry then
			return nil, "synced region '" .. id .. "' not found"
		end
		return entry
	end
	local player = core.get_player_by_name(playername)
	local entry = player and sync.get_at(player:get_pos())
	if not entry then
		return nil, "no synced region at your position, specify an id (see /bx_sync list)"
	end
	return entry
end

local function format_entry(entry, playername)
	local dirty_count = sync.count_dirty(entry)
	return entry.id .. ": " .. (entry.owner or "?") .. "/" .. (entry.schema_name or entry.schema_uid) ..
		" " .. core.pos_to_string(entry.pos1) .. " - " .. core.pos_to_string(entry.pos2) ..
		" [" .. (sync.can_write(playername, entry) and "rw" or "ro") .. "]" ..
		(entry.autosave and " [autosave]" or "") ..
		(dirty_count > 0 and (" [" .. dirty_count .. " parts changed]") or "") ..
		(entry.state ~= "ok" and (" [" .. entry.state .. "]") or "")
end

local subcommands = {}

function subcommands.status(playername, args)
	local entry, err = select_entry(playername, args[1])
	if not entry then
		return false, err
	end
	return blockexchange.api.count_next_schemapart_by_mtime(entry.schema_uid, entry.pulled_mtime):next(function(newer)
		return format_entry(entry, playername) .. ", remote: " ..
			((newer and newer > 0) and (newer .. " parts newer") or "up to date")
	end)
end

function subcommands.list(playername)
	local list = sync.list()
	if #list == 0 then
		return true, "No synced regions"
	end
	local lines = {}
	for _, entry in ipairs(list) do
		table.insert(lines, format_entry(entry, playername))
	end
	return true, table.concat(lines, "\n")
end

function subcommands.push(playername, args)
	local entry, err = select_entry(playername, args[1])
	if not entry then
		return false, err
	end
	if not sync.can_write(playername, entry) then
		return false, "you are not logged in as owner of the schematic"
	end
	return sync.push(playername, entry):next(function(stats)
		return "Pushed " .. stats.nodes .. " changed nodes in " .. stats.parts .. " parts"
	end)
end

function subcommands.pull(playername, args)
	if not core.check_player_privs(playername, { blockexchange = true }) then
		return false, "Required privs: blockexchange"
	end
	local policy = "abort"
	if args[1] == "mine" or args[1] == "theirs" then
		policy = table.remove(args, 1)
	end
	local entry, err = select_entry(playername, args[1])
	if not entry then
		return false, err
	end
	if entry.state ~= "ok" then
		return false, "the region has no sync baseline, use the /bx_sync ui to resolve it"
	end
	return sync.pull(playername, entry, policy):next(function(stats)
		return "Pulled " .. stats.remote_nodes .. " nodes in " .. stats.parts .. " parts" ..
			(stats.conflicts > 0 and (", " .. stats.conflicts .. " conflicts resolved (" .. policy .. ")") or "")
	end, function(e)
		if policy == "abort" then
			return Promise.rejected(tostring(e) .. " (use '/bx_sync pull mine' or '/bx_sync pull theirs')")
		end
		return Promise.rejected(e)
	end)
end

function subcommands.autosave(playername, args)
	local value = table.remove(args, 1)
	if value ~= "on" and value ~= "off" then
		return false, "Usage: /bx_sync autosave <on|off> [id]"
	end
	local entry, err = select_entry(playername, args[1])
	if not entry then
		return false, err
	end
	if not sync.can_write(playername, entry) then
		return false, "you are not logged in as owner of the schematic"
	end
	entry.autosave = value == "on"
	sync.save()
	return true, "Autosave of synced region '" .. entry.id .. "' " .. (entry.autosave and "enabled" or "disabled")
end

function subcommands.unlink(playername, args)
	local entry, err = select_entry(playername, args[1])
	if not entry then
		return false, err
	end
	local is_admin = core.check_player_privs(playername, { blockexchange = true })
	if not is_admin and entry.playername ~= playername then
		return false, "you are not allowed to unlink that region"
	end
	sync.remove(entry.id)
	return true, "Synced region '" .. entry.id .. "' unlinked (the build stays in the world)"
end

Promise.register_chatcommand("bx_sync", {
	params = "[status|list|push|pull [mine|theirs]|autosave <on|off>|unlink] [id]",
	description = "Synchronizes regions with the blockexchange (opens the ui without parameters)",
	func = function(playername, param)
		local args = (param or ""):split(" ")
		local subcommand = table.remove(args, 1)
		if not subcommand then
			blockexchange.sync_ui.show(playername):catch(function(e)
				blockexchange.log("error", "sync ui error for player '" .. playername .. "': " .. tostring(e))
				core.chat_send_player(playername, core.colorize("#ff0000", "[blockexchange] " .. tostring(e)))
			end)
			return true
		end
		local fn = subcommands[subcommand]
		if not fn then
			return false, usage
		end
		return fn(playername, args)
	end
})
