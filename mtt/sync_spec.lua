local sync = blockexchange.sync
local part = sync.part

local playername = "singleplayer"
local username = "Testuser"

-- 20x10x20 nodes: 2x1x2 parts
local pos1 = {x=200, y=0, z=0}
local pos2 = vector.add(pos1, {x=19, y=9, z=19})
local pos1_download = {x=200, y=0, z=100}

-- simulates a change by another client: patches the given node of the remote part
local function remote_change(await, token, entry, offset, pos, nodename)
    local schemapart, err = await(blockexchange.api.get_schemapart(entry.schema_uid, offset))
    if err or not schemapart then error("get_schemapart failed: " .. tostring(err), 0) end

    local remote = part.from_schemapart(schemapart)
    local changed = part.from_schemapart(schemapart)
    local part_pos1 = vector.add(entry.pos1, offset)
    changed.names[part.get_index(changed.size, vector.subtract(pos, part_pos1))] = nodename

    local filter = part.diff(remote, changed)
    local patch = await(blockexchange.create_schemapart(part.to_serialized(changed), offset, entry.schema_uid))
    local result
    result, err = await(blockexchange.api.patch_schemapart(token, patch, filter))
    if err or not result then error("patch failed: " .. tostring(err), 0) end
end

-- returns the remote node name at the absolute position
local function get_remote_node(await, entry, pos)
    local offset = sync.get_part_offset(entry, pos)
    local schemapart, err = await(blockexchange.api.get_schemapart(entry.schema_uid, offset))
    if err then error("get_schemapart failed: " .. err, 0) end
    if not schemapart then return "air" end
    local remote = part.from_schemapart(schemapart)
    return remote.names[part.get_index(remote.size, vector.subtract(pos, vector.add(entry.pos1, offset)))]
end

-- changes a local node, the dirty tracking happens through the autosave hooks
local function set_local_node(entry, pos, nodename)
    core.set_node(pos, { name = nodename })
    blockexchange.flush_sync_changes()
    assert(sync.is_dirty(entry, sync.get_part_offset(entry, pos)), "part not marked dirty")
end

local function assert_equal(a, b, msg)
    if a ~= b then
        error((msg or "assertion failed") .. ": expected '" .. tostring(b) .. "' got '" .. tostring(a) .. "'", 2)
    end
end

mtt.register("sync: upload, push, pull, conflicts and download", {
    timeout = 300,
    func = function(callback)
        Promise.async(function(await)
            sync.clear()

            local token, err = await(blockexchange.api.get_token(username, "default"))
            if err then error("get_token error: " .. tostring(err), 0) end
            local player_settings = blockexchange.get_player_settings(playername)
            player_settings.token = token
            blockexchange.set_player_settings(playername, player_settings)

            local _
            _, err = await(blockexchange.emerge(playername, pos1, vector.add(pos1_download, {x=19, y=9, z=19})))
            if err then error("emerge error: " .. tostring(err), 0) end

            -- initial build in part (0,0,0) only, part (16,0,0) stays air
            core.set_node(pos1, { name = "default:stone" })
            core.set_node(vector.add(pos1, {x=1, y=0, z=0}), { name = "default:stone" })
            core.set_node(vector.add(pos1, {x=2, y=0, z=0}), { name = "default:stone" })
            -- process the pending changes before the sync entry exists
            blockexchange.flush_sync_changes()

            -- upload
            local result
            result, err = await(sync.upload(playername, pos1, pos2, "sync_test_" .. math.random(10000)))
            if err then error("upload error: " .. tostring(err), 0) end
            local entry = result.entry
            assert(entry and entry.owner == username)
            assert_equal(#sync.list_baselines(entry), 1, "baselines after upload")
            assert(sync.get_baseline(entry, {x=0, y=0, z=0}))

            -- overlapping upload is rejected
            _, err = await(sync.upload(playername, pos1, pos2, "sync_test_overlap"))
            assert(err, "overlapping upload not rejected")

            -- push a local change
            local p_local = vector.add(pos1, {x=1, y=0, z=0})
            set_local_node(entry, p_local, "default:wood")
            local stats
            stats, err = await(sync.push(playername, entry))
            if err then error("push error: " .. tostring(err), 0) end
            assert_equal(stats.parts, 1, "pushed parts")
            assert_equal(stats.nodes, 1, "pushed nodes")
            assert_equal(sync.count_dirty(entry), 0, "dirty parts after push")
            assert_equal(get_remote_node(await, entry, p_local), "default:wood", "remote node after push")

            -- dirty part without changes is skipped
            sync.mark_dirty(entry, pos1)
            stats = await(sync.push(playername, entry))
            assert_equal(stats.parts, 0, "pushed parts without changes")
            assert_equal(stats.unchanged, 1, "unchanged parts")

            -- new part (air remotely) is created
            local p_new = vector.add(pos1, {x=17, y=0, z=0})
            set_local_node(entry, p_new, "default:dirt")
            stats, err = await(sync.push(playername, entry))
            if err then error("push error: " .. tostring(err), 0) end
            assert_equal(stats.created, 1, "created parts")
            assert_equal(get_remote_node(await, entry, p_new), "default:dirt", "remote node in new part")

            -- own changes come back on the next pull without changing anything
            local plan
            plan, err = await(sync.fetch(entry))
            if err then error("fetch error: " .. tostring(err), 0) end
            assert(#plan.parts >= 1)
            local analysis = sync.analyze(plan)
            assert_equal(analysis.remote_nodes, 0, "remote nodes of own changes")
            stats = await(sync.apply(playername, plan, "abort"))
            assert_equal(stats.parts, 0, "written parts of own changes")

            -- concurrent changes to different nodes of the same part are merged
            local p_remote = vector.add(pos1, {x=0, y=1, z=0})
            local p_local2 = vector.add(pos1, {x=0, y=2, z=0})
            remote_change(await, token, entry, {x=0, y=0, z=0}, p_remote, "default:glass")
            set_local_node(entry, p_local2, "default:cobble")

            plan = await(sync.fetch(entry))
            analysis = sync.analyze(plan)
            assert_equal(analysis.changed_parts, 1, "changed parts")
            assert_equal(analysis.conflicts, 0, "conflicts")
            stats, err = await(sync.apply(playername, plan, "abort"))
            if err then error("apply error: " .. tostring(err), 0) end
            assert_equal(stats.remote_nodes, 1, "applied remote nodes")
            assert_equal(core.get_node(p_remote).name, "default:glass", "merged remote node")
            assert_equal(core.get_node(p_local2).name, "default:cobble", "kept local node")
            assert_equal(core.get_node(p_local).name, "default:wood", "previously pushed node")
            assert(sync.is_dirty(entry, {x=0, y=0, z=0}), "part with local changes not dirty")

            -- push the remaining local change, the remote node stays
            await(sync.push(playername, entry))
            assert_equal(get_remote_node(await, entry, p_local2), "default:cobble", "pushed after merge")
            assert_equal(get_remote_node(await, entry, p_remote), "default:glass", "remote node after push")

            -- conflict: same node changed on both sides
            local p_conflict = vector.add(pos1, {x=0, y=3, z=0})
            remote_change(await, token, entry, {x=0, y=0, z=0}, p_conflict, "default:glass")
            set_local_node(entry, p_conflict, "default:wood")

            _, err = await(sync.pull(playername, entry, "abort"))
            assert(err, "conflict not detected")
            assert_equal(core.get_node(p_conflict).name, "default:wood", "node changed on abort")

            stats, err = await(sync.pull(playername, entry, "theirs"))
            if err then error("pull error: " .. tostring(err), 0) end
            assert_equal(stats.conflicts, 1, "resolved conflicts")
            assert_equal(core.get_node(p_conflict).name, "default:glass", "conflict resolution theirs")
            assert_equal(sync.count_dirty(entry), 0, "dirty parts after theirs")

            -- autosave pushes the change in the background
            entry.autosave = true
            local p_autosave = vector.add(pos1, {x=0, y=4, z=0})
            set_local_node(entry, p_autosave, "default:mese")
            local waited = 0
            while sync.count_dirty(entry) > 0 or sync.get_busy(entry) do
                if waited > 20 then error("autosave did not push the changes", 0) end
                await(Promise.after(0.5))
                waited = waited + 0.5
            end
            assert_equal(get_remote_node(await, entry, p_autosave), "default:mese", "remote node after autosave")
            entry.autosave = false
            sync.save()

            -- no autosave without write access
            entry.autosave = true
            local settings_backup = blockexchange.get_player_settings(playername)
            blockexchange.set_player_settings(playername, { license = "CC0" })
            set_local_node(entry, vector.add(pos1, {x=0, y=5, z=0}), "default:mese")
            await(Promise.after(2))
            assert_equal(sync.count_dirty(entry), 1, "dirty parts without write access")
            blockexchange.set_player_settings(playername, settings_backup)
            entry.autosave = false
            sync.clear_dirty(entry, {x=0, y=0, z=0})
            core.set_node(vector.add(pos1, {x=0, y=5, z=0}), { name = "air" })
            blockexchange.flush_sync_changes()
            sync.clear_dirty(entry, {x=0, y=0, z=0})
            sync.save()

            -- download into a new synced region
            result, err = await(sync.download(playername, pos1_download, entry.schema_uid, { owner = username }))
            if err then error("download error: " .. tostring(err), 0) end
            local entry2 = result.entry
            assert(entry2 and entry2.id ~= entry.id)
            assert_equal(#sync.list_baselines(entry2), 2, "baselines after download")
            local ok, msg = blockexchange.compare_area(pos1, pos2, pos1_download,
                vector.add(pos1_download, {x=19, y=9, z=19}), { check_param1 = false })
            if not ok then error("downloaded area does not match: " .. msg, 0) end

            -- overlapping download is rejected
            _, err = await(sync.download(playername, pos1_download, entry.schema_uid))
            assert(err, "overlapping download not rejected")

            -- nothing to pull for the fresh download
            plan = await(sync.fetch(entry2))
            assert_equal(#plan.parts, 0, "parts to pull after download")

            -- no baseline, remote wins: the remote schematic is placed again,
            -- parts without remote counterpart are cleared
            entry2.state = "needs_baseline"
            _, err = await(sync.push(playername, entry2))
            assert(err, "push without baseline not rejected")
            local p_changed = vector.add(pos1_download, {x=5, y=5, z=5})
            local p_stray = vector.add(pos1_download, {x=17, y=0, z=17})
            core.set_node(p_changed, { name = "default:wood" })
            core.set_node(p_stray, { name = "default:dirt" })
            blockexchange.flush_sync_changes()
            _, err = await(sync.resolve_remote(playername, entry2))
            if err then error("resolve_remote error: " .. tostring(err), 0) end
            assert_equal(entry2.state, "ok", "state after resolve_remote")
            assert_equal(sync.count_dirty(entry2), 0, "dirty parts after resolve_remote")
            assert_equal(core.get_node(p_changed).name, "air", "local change not reverted")
            assert_equal(core.get_node(p_stray).name, "air", "part without remote counterpart not cleared")
            ok, msg = blockexchange.compare_area(pos1, pos2, pos1_download,
                vector.add(pos1_download, {x=19, y=9, z=19}), { check_param1 = false })
            if not ok then error("remote region does not match: " .. msg, 0) end

            -- no baseline, local wins: the remote parts become the baseline, only the local differences are pushed
            entry.state = "needs_baseline"
            local p_local3 = vector.add(pos1, {x=3, y=0, z=0})
            set_local_node(entry, p_local3, "default:wood")
            _, err = await(sync.resolve_local(entry))
            if err then error("resolve_local error: " .. tostring(err), 0) end
            assert_equal(entry.state, "ok", "state after resolve_local")
            assert_equal(sync.count_dirty(entry), 4, "dirty parts after resolve_local")
            stats, err = await(sync.push(playername, entry))
            if err then error("push error: " .. tostring(err), 0) end
            assert_equal(stats.nodes, 1, "pushed nodes after resolve_local")
            assert_equal(stats.unchanged, 3, "unchanged parts after resolve_local")
            assert_equal(get_remote_node(await, entry, p_local3), "default:wood", "remote node after resolve_local")
        end):next(function()
            callback()
        end):catch(function(e)
            error(e, 0)
        end)
    end
})
