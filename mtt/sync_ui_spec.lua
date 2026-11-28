local sync = blockexchange.sync
local sync_ui = blockexchange.sync_ui
local part = sync.part

local playername = "sync_ui_player"
local username = "Testuser"
local schemaname = "sync_ui_" .. math.random(10000)

-- 20x5x20 nodes: 2x1x2 parts
local pos1 = {x=400, y=0, z=0}
local pos2 = vector.add(pos1, {x=19, y=4, z=19})
local pos1_download = {x=400, y=0, z=100}
local pos2_download = vector.add(pos1_download, {x=19, y=4, z=19})

-- replaces Promise.formspec with scripted responses
-- @param responses list of fields tables or functions(formspec) -> fields
-- @return the list of shown formspecs and a restore function
local function script_formspecs(responses)
    local old_formspec = Promise.formspec
    local shown = {}
    Promise.formspec = function(_, fs) -- luacheck: ignore 122
        table.insert(shown, fs)
        local response = table.remove(responses, 1)
        if type(response) == "function" then
            response = response(fs)
        end
        if not response then
            error("unexpected formspec #" .. #shown .. ": " .. fs, 0)
        end
        response.quit = "true"
        return Promise.after(0):next(function()
            return response
        end)
    end
    return shown, function(err)
        Promise.formspec = old_formspec -- luacheck: ignore 122
        if err then
            error(err, 0)
        end
        if #responses > 0 then
            error(#responses .. " scripted formspec responses left", 0)
        end
    end
end

-- returns a response function that checks the formspec for the given (unescaped) text
local function expect(text, fields)
    return function(fs)
        if not fs:find(core.formspec_escape(text), 1, true) then
            error("text '" .. text .. "' not found in formspec: " .. fs, 0)
        end
        return fields
    end
end

-- simulates a change by another client: patches the given node of the remote part
local function remote_change(await, token, entry, pos, nodename)
    local offset = sync.get_part_offset(entry, pos)
    local schemapart, err = await(blockexchange.api.get_schemapart(entry.schema_uid, offset))
    if err or not schemapart then error("get_schemapart failed: " .. tostring(err), 0) end
    local remote = part.from_schemapart(schemapart)
    local changed = part.from_schemapart(schemapart)
    changed.names[part.get_index(changed.size, vector.subtract(pos, vector.add(entry.pos1, offset)))] = nodename
    local patch = await(blockexchange.create_schemapart(part.to_serialized(changed), offset, entry.schema_uid))
    local result
    result, err = await(blockexchange.api.patch_schemapart(token, patch, part.diff(remote, changed)))
    if err or not result then error("patch failed: " .. tostring(err), 0) end
end

mtt.register("sync ui: wizards, status page and pull dialog", {
    timeout = 300,
    func = function(callback)
        Promise.async(function(await)
            sync.clear()
            local player = mtt.join_player(playername)
            core.set_player_privs(playername, { interact = true, blockexchange = true })
            player:set_pos({x=0, y=0, z=0})

            local token, err = await(blockexchange.api.get_token(username, "default"))
            if err then error("get_token error: " .. tostring(err), 0) end
            local player_settings = blockexchange.get_player_settings(playername)
            player_settings.token = token
            blockexchange.set_player_settings(playername, player_settings)

            local _
            _, err = await(blockexchange.emerge(playername, pos1, pos2_download))
            if err then error("emerge error: " .. tostring(err), 0) end
            core.set_node(pos1, { name = "default:stone" })
            core.set_node(vector.add(pos1, {x=17, y=0, z=17}), { name = "default:dirt" })
            blockexchange.flush_sync_changes()

            blockexchange.set_pos(1, playername, pos1)
            blockexchange.set_pos(2, playername, pos2)

            -- escape cancels the wizard
            local _, restore = script_formspecs({ expect("Upload: Selection", {}) })
            local ctx
            ctx, err = await(sync_ui.show_upload(playername))
            restore(err)
            assert(ctx == nil, "wizard not canceled")

            -- invalid name stays on the step with an error
            _, restore = script_formspecs({
                expect("[ok] logged in as 'Testuser'", { btn_next = "Next" }),
                expect("Upload: Target", { schemaname = "invalid name!", btn_next = "Next" }),
                expect("the name can only contain", { btn_cancel = "Cancel" })
            })
            ctx, err = await(sync_ui.show_upload(playername))
            restore(err)
            assert(ctx == nil)

            -- upload as synced region (autosave disabled)
            _, restore = script_formspecs({
                { btn_next = "Next" },
                { schemaname = schemaname, btn_next = "Next" },
                expect("Upload: Options", { btn_toggle_autosave = "" }),
                { btn_next = "Next" },
                expect("autosave: off", { btn_next = "Upload" }),
                expect("Upload complete", { btn_close = "Close" })
            })
            ctx, err = await(sync_ui.show_upload(playername))
            restore(err and ("upload wizard error: " .. tostring(err)))
            local entry = ctx.entry
            assert(entry and sync.get_at(pos1) == entry, "no synced region after upload")
            assert(entry.schema_name == schemaname)
            assert(not entry.autosave, "autosave enabled")

            -- overlapping selection blocks the upload wizard
            _, restore = script_formspecs({
                expect("[x] overlaps synced region '" .. entry.id .. "'", { btn_next = "Next" }),
                expect("Upload: Selection", { btn_cancel = "Cancel" })
            })
            _, err = await(sync_ui.show_upload(playername))
            restore(err)

            -- status page: push a local change
            player:set_pos(vector.add(pos1, 1))
            core.set_node(vector.add(pos1, {x=1, y=0, z=0}), { name = "default:wood" })
            blockexchange.flush_sync_changes()
            _, restore = script_formspecs({
                expect("1 parts changed", { btn_push = "Push" }),
                expect("Pushed 1 changed nodes in 1 parts", { btn_close = "Close" })
            })
            _, err = await(sync_ui.show(playername))
            restore(err)
            assert(sync.count_dirty(entry) == 0, "dirty parts after push")

            -- download wizard into a synced read-only region
            player:set_pos({x=0, y=0, z=0})
            blockexchange.set_pos(1, playername, pos1_download)
            _, restore = script_formspecs({
                expect("Upload selection", { btn_download = "Download" }),
                expect("Download: Source", { source = username .. "/" .. schemaname, btn_next = "Next" }),
                expect("Target: " .. core.pos_to_string(pos1_download), { btn_next = "Next" }),
                expect("Download: Mode", { btn_next = "Next" }),
                expect("synced, read-only", { btn_next = "Download" }),
                expect("Download complete", { btn_close = "Close" })
            })
            ctx, err = await(sync_ui.show(playername))
            restore(err and ("download wizard error: " .. tostring(err)))
            local entry2 = ctx.entry
            assert(entry2 and sync.get_at(pos1_download) == entry2, "no synced region after download")
            assert(entry2.owner == username)
            local ok, msg = blockexchange.compare_area(pos1, pos2, pos1_download, pos2_download,
                { check_param1 = false })
            if not ok then error("downloaded area does not match: " .. msg, 0) end

            -- unknown schematic
            _, restore = script_formspecs({
                { source = username .. "/does_not_exist_" .. math.random(10000), btn_next = "Next" },
                expect("schematic not found", { btn_cancel = "Cancel" })
            })
            _, err = await(sync_ui.show_download(playername))
            restore(err)

            -- pull dialog with a conflict, keep mine
            local p_remote = vector.add(pos1_download, {x=0, y=1, z=0})
            local p_conflict = vector.add(pos1_download, {x=0, y=2, z=0})
            remote_change(await, token, entry, vector.add(pos1, {x=0, y=1, z=0}), "default:glass")
            remote_change(await, token, entry, vector.add(pos1, {x=0, y=2, z=0}), "default:glass")
            core.set_node(p_conflict, { name = "default:cobble" })
            blockexchange.flush_sync_changes()

            player:set_pos(vector.add(pos1_download, 1))
            _, restore = script_formspecs({
                expect("1 parts newer", { btn_pull = "Pull..." }),
                expect("1 parts with 1 conflicting nodes", { btn_policy_mine = "" }),
                { btn_apply = "Apply" },
                expect("1 conflicts resolved (mine)", { btn_close = "Close" })
            })
            _, err = await(sync_ui.show(playername))
            restore(err)
            assert(core.get_node(p_remote).name == "default:glass", "remote change not pulled")
            assert(core.get_node(p_conflict).name == "default:cobble", "local node not kept")
            assert(sync.is_dirty(entry2, {x=0, y=0, z=0}), "local change not dirty after pull")

            -- region list and unlink through the status page
            player:set_pos({x=0, y=0, z=0})
            _, restore = script_formspecs({
                { btn_list = "Synced regions" },
                expect(entry2.id, { btn_status_1 = "Status" }),
                { btn_unlink = "Unlink..." },
                expect("Remove the sync information", { btn_unlink = "Unlink" })
            })
            _, err = await(sync_ui.show(playername))
            restore(err)
            assert(#sync.list() == 1, "region not unlinked")
            assert(core.get_node(p_conflict).name == "default:cobble", "build changed by unlink")

            -- chat command
            local cmd = core.registered_chatcommands.bx_sync
            local success, text = cmd.func(playername, "list")
            assert(success and text:find(entry.id, 1, true), "list command: " .. tostring(text))
            success = cmd.func(playername, "autosave on " .. entry.id)
            assert(success and entry.autosave, "autosave command")
            cmd.func(playername, "autosave off " .. entry.id)
            success, text = cmd.func(playername, "push")
            assert(not success and text:find("no synced region at your position", 1, true), "push without region")
            success, text = cmd.func(playername, "unknown")
            assert(not success and text:find("Usage", 1, true))

            mtt.leave_player(playername)
        end):next(function()
            callback()
        end):catch(function(e)
            print(e)
            callback(e)
        end)
    end
})
