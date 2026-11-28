local sync = blockexchange.sync

local playername = "singleplayer"
local username = "Testuser"

-- 20x5x20 nodes: 2x1x2 parts
local size = {x=19, y=4, z=19}
local pos1 = {x=600, y=0, z=0}
local pos2 = vector.add(pos1, size)
local pos1_remote = {x=600, y=0, z=100}
local pos2_remote = vector.add(pos1_remote, size)
local pos1_storage = {x=600, y=0, z=200}

local function assert_equal(a, b, msg)
    if a ~= b then
        error((msg or "assertion failed") .. ": expected '" .. tostring(b) .. "' got '" .. tostring(a) .. "'", 2)
    end
end

local function legacy_area(id, p1, schema, autosave)
    return {
        id = id,
        pos1 = p1,
        pos2 = vector.add(p1, size),
        schema_uid = schema.uid,
        mtime = schema.mtime,
        name = schema.name,
        username = username,
        playername = playername,
        autosave = autosave,
        autoload = false
    }
end

mtt.register("sync: migration of legacy areas", {
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
            _, err = await(blockexchange.emerge(playername, pos1, vector.add(pos1_storage, size)))
            if err then error("emerge error: " .. tostring(err), 0) end

            -- schematic uploaded with the old (plain) save, content in part (0,0,0) only
            core.set_node(pos1, { name = "default:stone" })
            core.set_node(vector.add(pos1, {x=1, y=0, z=0}), { name = "default:stone" })
            blockexchange.flush_sync_changes()
            local result
            result, err = await(blockexchange.save(playername, pos1, pos2, "migrate_" .. math.random(10000)))
            if err then error("save error: " .. tostring(err), 0) end
            local schema = result.schema

            -- migration: invalid and overlapping areas are skipped
            local migrated, skipped = sync.migrate_areas({
                abcde = legacy_area("abcde", pos1, schema, true),
                fghij = legacy_area("fghij", pos1, schema, true),
                broken = { foo = "bar" },
                klmno = legacy_area("klmno", pos1_remote, schema, false)
            })
            assert_equal(migrated, 2, "migrated areas")
            assert_equal(skipped, 2, "skipped areas")

            local entry = sync.get_at(pos1)
            assert(entry and (entry.id == "abcde" or entry.id == "fghij"), "area id not kept")
            assert_equal(entry.state, "needs_baseline", "state")
            assert_equal(entry.owner, username, "owner")
            assert(entry.autosave, "autosave not migrated")
            assert(not sync.can_write(playername, entry), "writable without owner uid")

            -- owner uid lookup
            local updated = await(sync.update_missing_owners())
            assert_equal(updated, 2, "updated owners")
            assert(sync.can_write(playername, entry), "not writable after owner lookup")

            -- no push and no autosave without baseline
            core.set_node(vector.add(pos1, {x=2, y=0, z=0}), { name = "default:wood" })
            blockexchange.flush_sync_changes()
            _, err = await(sync.push(playername, entry))
            assert(err, "push without baseline not rejected")
            await(Promise.after(1.5))
            assert(sync.count_dirty(entry) > 0, "autosave pushed without baseline")

            -- local wins: the remote parts become the baseline, only the local differences are pushed
            entry.autosave = false
            _, err = await(sync.resolve_local(entry))
            if err then error("resolve_local error: " .. tostring(err), 0) end
            assert_equal(entry.state, "ok", "state after resolve_local")
            assert_equal(sync.count_dirty(entry), 4, "dirty parts after resolve_local")
            local stats
            stats, err = await(sync.push(playername, entry))
            if err then error("push error: " .. tostring(err), 0) end
            assert_equal(stats.nodes, 1, "pushed nodes")
            assert_equal(stats.unchanged, 3, "unchanged parts")

            -- remote wins: the remote schematic is placed again, parts without remote counterpart are cleared
            local entry_remote = sync.get_at(pos1_remote)
            assert(entry_remote and entry_remote.id == "klmno")
            local p_stray = vector.add(pos1_remote, {x=17, y=0, z=17})
            core.set_node(p_stray, { name = "default:dirt" })
            _, err = await(sync.resolve_remote(playername, entry_remote))
            if err then error("resolve_remote error: " .. tostring(err), 0) end
            assert_equal(entry_remote.state, "ok", "state after resolve_remote")
            assert_equal(sync.count_dirty(entry_remote), 0, "dirty parts after resolve_remote")
            assert_equal(core.get_node(p_stray).name, "air", "part without remote counterpart not cleared")
            local ok, msg = blockexchange.compare_area(pos1, pos2, pos1_remote, pos2_remote, { check_param1 = false })
            if not ok then error("remote region does not match: " .. msg, 0) end

            -- startup migration from the mod storage, the legacy data is backed up and removed
            local storage = blockexchange.mod_storage
            storage:set_string("areas_v3", core.write_json({
                pqrst = legacy_area("pqrst", pos1_storage, schema, false)
            }))
            migrated, skipped = sync.migrate_legacy()
            assert_equal(migrated, 1, "migrated areas from storage")
            assert_equal(skipped, 0, "skipped areas from storage")
            assert(sync.get("pqrst"), "storage area not migrated")
            assert_equal(storage:get_string("areas_v3"), "", "legacy data not removed")
            assert(storage:get_string("areas_v3_migrated"):find("pqrst", 1, true), "no backup")
            migrated = sync.migrate_legacy()
            assert_equal(migrated, 0, "migrated twice")

            -- deprecated commands point to the replacement
            local success, text = core.registered_chatcommands.bx_save_update.func(playername, "")
            assert(success and text:find("/bx_sync push", 1, true), "deprecation stub: " .. tostring(text))
        end):next(function()
            callback()
        end):catch(function(e)
            print(e)
            callback(e)
        end)
    end
})
