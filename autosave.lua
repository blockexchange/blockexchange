---------
-- change tracking and autosave of synced regions

-- sync entry autosave

-- entry.id -> { failures = <consecutive failures>, next_attempt = <os.time()> }
local sync_backoff = {}

--- returns true if the sync entry is pushed automatically
local function is_sync_autosave(entry)
    return entry.autosave and
        entry.state == "ok" and
        entry.playername ~= nil and
        blockexchange.sync.can_write(entry.playername, entry)
end

-- list of changed mapblocks pending for the sync dirty tracking
local sync_mapblocks = {}

--- marks the parts of all sync entries affected by the pending changes as dirty
-- called periodically, can be called directly to process the changes immediately (tests)
function blockexchange.flush_sync_changes()
    local changed = false
    for mapblock_pos_str in pairs(sync_mapblocks) do
        local pos1, pos2 = blockexchange.get_mapblock_bounds_from_mapblock(core.string_to_pos(mapblock_pos_str))
        for _, entry in ipairs(blockexchange.sync.get_in_area(pos1, pos2)) do
            if blockexchange.sync.mark_dirty(entry, pos1, pos2) then
                changed = true
            end
        end
    end
    sync_mapblocks = {}

    if changed then
        blockexchange.sync.save()
    end
end

-- starts a push for every autosave entry with dirty parts (not awaited, busy entries are skipped)
local function push_sync_entries()
    local sync = blockexchange.sync
    local now = os.time()
    for _, entry in ipairs(sync.list()) do
        local backoff = sync_backoff[entry.id]
        if sync.count_dirty(entry) > 0 and
            not sync.get_busy(entry) and
            (not backoff or backoff.next_attempt <= now) and
            is_sync_autosave(entry) then

            blockexchange.log("action", "autosaving sync entry " .. entry.id ..
                " playername: " .. entry.playername ..
                " parts: " .. sync.count_dirty(entry))

            sync.push(entry.playername, entry):next(function()
                sync_backoff[entry.id] = nil
            end):catch(function(err)
                local failures = (backoff and backoff.failures or 0) + 1
                -- 30s, 60s, 120s ... max 10 minutes
                local delay = math.min(30 * 2 ^ (failures - 1), 600)
                sync_backoff[entry.id] = { failures = failures, next_attempt = os.time() + delay }
                blockexchange.log("error", "autosave failed for sync entry: " .. entry.id ..
                    " reason: " .. tostring(err) .. ", retrying in " .. delay .. " seconds")
            end)
        end
    end
end

local function sync_worker()
    blockexchange.flush_sync_changes()
    push_sync_entries()
    core.after(1, sync_worker)
end

if blockexchange.is_online then
    core.after(1, sync_worker)
end

-- change tracking code below

function blockexchange.mark_changed(pos1, pos2)
    assert(pos1, "pos1 is not nil")
    pos2 = pos2 or pos1

    if not blockexchange.is_online then
        -- can't save online
        return
    end

    pos1, pos2 = blockexchange.sort_pos(pos1, pos2)

    local mapblock_pos1 = blockexchange.get_mapblock(pos1)
    local mapblock_pos2 = blockexchange.get_mapblock(pos2)
    for x=mapblock_pos1.x,mapblock_pos2.x do
        for y=mapblock_pos1.y,mapblock_pos2.y do
            for z=mapblock_pos1.z,mapblock_pos2.z do
                local mapblock_pos = {x=x, y=y, z=z}
                local mapblock_pos_str = core.pos_to_string(mapblock_pos)
                sync_mapblocks[mapblock_pos_str] = true
            end
        end
    end
end

-- NOTE: there are too many changes reporting, we are basically saving the whole time
-- disabled until there is a solution or alternative
local enable_builtin_mapblock_change_detection = false

if type(core.register_on_mapblocks_changed) == "function" and enable_builtin_mapblock_change_detection then
    -- builtin change detection
    core.register_on_mapblocks_changed(function(modified_blocks)
        for mapblock_hash in pairs(modified_blocks) do
            local mapblock_pos = core.get_position_from_hash(mapblock_hash)
            local pos1, pos2 = blockexchange.get_mapblock_bounds_from_mapblock(mapblock_pos)
            blockexchange.mark_changed(pos1, pos2)
        end
    end)
else
    -- shim various api's to be aware of world-changes

    -- autosave on core.set_node
    local old_set_node = core.set_node
    function core.set_node(pos, node)
        blockexchange.mark_changed(pos, pos)
        return old_set_node(pos, node)
    end

    -- autosave on core.swap_node
    local old_swap_node = core.swap_node
    function core.swap_node(pos, node)
        blockexchange.mark_changed(pos, pos)
        return old_swap_node(pos, node)
    end

    -- autosave on place/dignode
    local function place_dig_callback(pos)
        blockexchange.mark_changed(pos, pos)
    end
    core.register_on_placenode(place_dig_callback)
    core.register_on_dignode(place_dig_callback)

    -- autosave on we commands
    if core.get_modpath("worldedit") then
        -- used by various primitives and commands
        local old_mapgenhelper_init = worldedit.manip_helpers.init
        worldedit.manip_helpers.init = function(pos1, pos2)
            blockexchange.mark_changed(pos1, pos2)
            return old_mapgenhelper_init(pos1, pos2)
        end

        -- used by //load and others
        local old_keeploaded = worldedit.keep_loaded
        worldedit.keep_loaded = function(pos1, pos2)
            blockexchange.mark_changed(pos1, pos2)
            return old_keeploaded(pos1, pos2)
        end

        -- //fixlight
        local old_fixlight = worldedit.fixlight
        worldedit.fixlight = function(pos1, pos2)
            blockexchange.mark_changed(pos1, pos2)
            return old_fixlight(pos1, pos2)
        end
    end

    -- intercept various node-based events
    core.register_on_mods_loaded(function()
        for nodename, def in pairs(core.registered_nodes) do
            if type(def.on_receive_fields) == "function" then
                -- intercept formspec events
                local old_on_receive_fields = def.on_receive_fields
                core.override_item(nodename, {
                    on_receive_fields = function(pos, formname, fields, sender)
                        blockexchange.mark_changed(pos, pos)
                        return old_on_receive_fields(pos, formname, fields, sender)
                    end
                })
            end

            if type(def.on_metadata_inventory_move) == "function" then
                -- intercept inv move event
                local old_inv_move = def.on_metadata_inventory_move
                core.override_item(nodename, {
                    on_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
                        blockexchange.mark_changed(pos, pos)
                        return old_inv_move(pos, from_list, from_index, to_list, to_index, count, player)
                    end
                })
            end

            if type(def.on_metadata_inventory_put) == "function" then
                -- intercept inv put event
                local old_inv_put = def.on_metadata_inventory_put
                core.override_item(nodename, {
                    on_metadata_inventory_put = function(pos, listname, index, stack, player)
                        blockexchange.mark_changed(pos, pos)
                        return old_inv_put(pos, listname, index, stack, player)
                    end
                })
            end

            if type(def.on_metadata_inventory_take) == "function" then
                -- intercept inv take event
                local old_inv_take = def.on_metadata_inventory_take
                core.override_item(nodename, {
                    on_metadata_inventory_take = function(pos, listname, index, stack, player)
                        blockexchange.mark_changed(pos, pos)
                        return old_inv_take(pos, listname, index, stack, player)
                    end
                })
            end

        end
    end)
end