

-- pos_hash -> {pos1, pos2, schema}
-- TODO: persist on shutdown / load on startup
local autosave_controllers = {}

-- area cache
local autosave_areas = AreaStore()

function blockexchange.enable_autosave(controller_pos)
    local hash = "" .. minetest.hash_node_position(controller_pos)
    local meta = minetest.get_meta(controller_pos)
    local owner = meta:get_string("owner")
    local claims = blockexchange.get_claims(owner)
    local schema = minetest.deserialize(meta:get_string("schema"))
    local origin = minetest.deserialize(meta:get_string("origin"))
    local pos2 = vector.add(origin, vector.subtract({ x=schema.size_x, y=schema.size_y, z=schema.size_z }, 1))

    -- TODO: validate vars

    local ctx = {
        type = "autosave",
        controller_pos = controller_pos,
        username = claims.username,
        pos1 = origin,
        pos2 = pos2,
        schema = schema,
        area_id = autosave_areas:insert_area(origin, pos2, hash),
        owner = owner,
        update_count = 0
    }

    autosave_controllers[hash] = ctx
    blockexchange.set_job_context(owner, ctx)
end

function blockexchange.disable_autosave(controller_pos)
    local hash = "" .. minetest.hash_node_position(controller_pos)
    local ctx = autosave_controllers[hash]
    if ctx then
        autosave_areas:remove_area(ctx.area_id)
        blockexchange.set_job_context(ctx.owner, nil)
        autosave_controllers[hash] = nil
    end
end

function blockexchange.get_autosave(controller_pos)
    local hash = "" .. minetest.hash_node_position(controller_pos)
    return autosave_controllers[hash]
end

-- list of changed mapblocks marked for export
local mapblocks = {}

-- autosave worker function
local function worker()
    -- check cancel flag
    local contexts = blockexchange.get_job_contexts()
    for _, ctx in pairs(contexts) do
        if ctx.type == "autosave" and ctx.cancel then
            blockexchange.disable_autosave(ctx.controller_pos)
        end
    end

    -- go through all changed mapblocks and update the regions where autosave is enabled
    for hash in pairs(mapblocks) do
        local mapblock_pos = minetest.get_position_from_hash(hash)
        local pos1, pos2 = blockexchange.get_mapblock_bounds_from_mapblock(mapblock_pos)

        local list = autosave_areas:get_areas_in_area(pos1, pos2, true, true, true)
        for _, entry in pairs(list) do
            local autosave_hash = entry.data
            local ctx = autosave_controllers[autosave_hash]
            ctx.update_count = ctx.update_count + 1
            blockexchange.save_update_area(ctx.owner, ctx.pos1, ctx.pos2, pos1, pos2, ctx.username, ctx.schema.name)
        end
    end

    mapblocks = {}
    minetest.after(5, worker)
end

minetest.after(1, worker)

local function deferred_export(pos1, pos2)
    pos1, pos2 = blockexchange.sort_pos(pos1, pos2)

    local mapblock_pos1 = blockexchange.get_mapblock(pos1)
    local mapblock_pos2 = blockexchange.get_mapblock(pos2)
    for x=mapblock_pos1.x,mapblock_pos2.x do
        for y=mapblock_pos1.y,mapblock_pos2.y do
            for z=mapblock_pos1.z,mapblock_pos2.z do
                local mapblock_pos = {x=x, y=y, z=z}
                local hash = minetest.hash_node_position(mapblock_pos)
                mapblocks[hash] = true
            end
        end
    end
end

-- autosave on minetest.set_node
local old_set_node = minetest.set_node
function minetest.set_node(pos, node)
    deferred_export(pos, pos)
    return old_set_node(pos, node)
end

-- autosave on minetest.swap_node
local old_swap_node = minetest.swap_node
function minetest.swap_node(pos, node)
    deferred_export(pos, pos)
    return old_swap_node(pos, node)
end

-- autosave on place/dignode
local function place_dig_callback(pos)
    deferred_export(pos, pos)
end
minetest.register_on_placenode(place_dig_callback)
minetest.register_on_dignode(place_dig_callback)

-- autosave on we commands
if minetest.get_modpath("worldedit") then
    -- used by various primitives and commands
    local old_mapgenhelper_init = worldedit.manip_helpers.init
    worldedit.manip_helpers.init = function(pos1, pos2)
        deferred_export(pos1, pos2)
        return old_mapgenhelper_init(pos1, pos2)
    end

    -- used by //load and others
    local old_keeploaded = worldedit.keep_loaded
    worldedit.keep_loaded = function(pos1, pos2)
        deferred_export(pos1, pos2)
        return old_keeploaded(pos1, pos2)
    end
end

-- intercept various node-based events
minetest.register_on_mods_loaded(function()
    for nodename, def in pairs(minetest.registered_nodes) do
        if type(def.on_receive_fields) == "function" then
            -- intercept formspec events
            local old_on_receive_fields = def.on_receive_fields
            minetest.override_item(nodename, {
                on_receive_fields = function(pos, formname, fields, sender)
                    deferred_export(pos, pos)
                    return old_on_receive_fields(pos, formname, fields, sender)
                end
            })
        end

        if type(def.on_metadata_inventory_move) == "function" then
            -- intercept inv move event
            local old_inv_move = def.on_metadata_inventory_move
            minetest.override_item(nodename, {
                on_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
                    deferred_export(pos, pos)
                    return old_inv_move(pos, from_list, from_index, to_list, to_index, count, player)
                end
            })
        end

        if type(def.on_metadata_inventory_put) == "function" then
            -- intercept inv put event
            local old_inv_put = def.on_metadata_inventory_put
            minetest.override_item(nodename, {
                on_metadata_inventory_put = function(pos, listname, index, stack, player)
                    deferred_export(pos, pos)
                    return old_inv_put(pos, listname, index, stack, player)
                end
            })
        end

        if type(def.on_metadata_inventory_take) == "function" then
            -- intercept inv take event
            local old_inv_take = def.on_metadata_inventory_take
            minetest.override_item(nodename, {
                on_metadata_inventory_take = function(pos, listname, index, stack, player)
                    deferred_export(pos, pos)
                    return old_inv_take(pos, listname, index, stack, player)
                end
            })
        end

    end
end)