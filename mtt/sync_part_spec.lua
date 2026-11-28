local part = blockexchange.sync.part

local size = {x=2, y=2, z=2}

-- creates a part from a list of node names (index order), param2 and metadata are optional
local function create(names, opts)
    opts = opts or {}
    local p = part.air(size)
    for i, name in ipairs(names) do
        p.names[i] = name
    end
    for i, v in pairs(opts.param2 or {}) do
        p.param2[i] = v
    end
    for i, v in pairs(opts.meta or {}) do
        p.meta[i] = v
    end
    for i, v in pairs(opts.timers or {}) do
        p.timers[i] = v
    end
    return p
end

local function filter_bytes(filter)
    local list = {}
    for i = 1, #filter do
        list[i] = string.byte(filter, i)
    end
    return list
end

mtt.register("sync part: index and position", function(callback)
    local s = {x=3, y=4, z=5}
    for i = 1, 60 do
        assert(part.get_index(s, part.get_pos(s, i)) == i)
    end
    -- z changes fastest, x slowest
    assert(vector.equals(part.get_pos(s, 2), {x=0, y=0, z=1}))
    assert(vector.equals(part.get_pos(s, 6), {x=0, y=1, z=0}))
    assert(vector.equals(part.get_pos(s, 21), {x=1, y=0, z=0}))
    callback()
end)

mtt.register("sync part: diff", function(callback)
    local base = create({"default:stone", "default:dirt"}, {
        meta = { [3] = { fields = { a = "1" }, inventory = {} } }
    })

    -- identical, light is ignored
    local loc = create({"default:stone", "default:dirt"}, {
        meta = { [3] = { fields = { a = "1" } } }
    })
    loc.param1[1] = 15
    local _, filter, changed
    filter, changed = part.diff(base, loc)
    assert(changed == 0)
    assert(#filter == 8)

    -- name, param2, metadata and removed metadata
    loc = create({"default:wood", "default:dirt", "air", "air", "air", "air", "air", "air"}, {
        param2 = { [2] = 3 },
        meta = { [4] = { fields = { b = "2" } } }
    })
    filter, changed = part.diff(base, loc)
    assert(changed == 4)
    local bytes = filter_bytes(filter)
    assert(bytes[1] == part.PATCH_ALL)
    assert(bytes[2] == part.PATCH_PARAM2)
    assert(bytes[3] == part.PATCH_METADATA)
    assert(bytes[4] == part.PATCH_METADATA)
    assert(bytes[5] == 0)

    -- timers are compared by timeout only
    base.timers[5] = { timeout = 2, elapsed = 0 }
    loc = create({"default:stone", "default:dirt"}, {
        meta = { [3] = { fields = { a = "1" } } },
        timers = { [5] = { timeout = 2, elapsed = 1.5 } }
    })
    _, changed = part.diff(base, loc)
    assert(changed == 0)
    loc.timers[5].timeout = 3
    _, changed = part.diff(base, loc)
    assert(changed == 1)

    callback()
end)

mtt.register("sync part: 3-way merge", function(callback)
    local base = create({"default:stone", "default:stone", "default:stone", "default:stone"})
    -- 1: changed locally, 2: changed remotely, 3: changed on both sides (conflict), 4: same change on both sides
    local loc = create({"default:wood", "default:stone", "default:wood", "default:dirt"})
    local remote = create({"default:stone", "default:glass", "default:glass", "default:dirt"})

    local _
    local merged, stats = part.merge(base, loc, remote, "mine")
    assert(merged.names[1] == "default:wood")
    assert(merged.names[2] == "default:glass")
    assert(merged.names[3] == "default:wood")
    assert(merged.names[4] == "default:dirt")
    assert(merged.names[5] == "air")
    assert(stats.remote_nodes == 1)
    assert(stats.conflicts == 1)
    assert(stats.local_nodes == 2)
    assert(#stats.remote_indices == 1 and stats.remote_indices[1] == 2)

    merged, stats = part.merge(base, loc, remote, "theirs")
    assert(merged.names[1] == "default:wood")
    assert(merged.names[3] == "default:glass")
    assert(stats.remote_nodes == 2)
    assert(stats.conflicts == 1)
    assert(stats.local_nodes == 1)

    -- remote unchanged: nothing to apply
    _, stats = part.merge(base, loc, base, "theirs")
    assert(stats.remote_nodes == 0 and stats.conflicts == 0)

    -- size mismatch
    assert(not pcall(part.merge, base, loc, part.air({x=1, y=2, z=2})))

    callback()
end)

mtt.register("sync part: encoding round trip", function(callback)
    local p = create({"default:stone", "default:dirt", "default:stone"}, {
        param2 = { [2] = 7 },
        meta = { [3] = { fields = { infotext = "hello" }, inventory = { main = { "default:dirt 5", "" } } } },
        timers = { [3] = { timeout = 5, elapsed = 1 } }
    })
    p.param1[1] = 12

    local data = part.to_serialized(p)
    assert(#data.node_ids == 8)
    assert(data.metadata.meta["(0,1,0)"].fields.infotext == "hello")

    -- serialized format
    local p2 = part.from_serialized(data)
    assert(p2.names[2] == "default:dirt" and p2.param2[2] == 7 and p2.param1[1] == 12)
    local _, changed = part.diff(p, p2)
    assert(changed == 0)

    -- raw bytes, same layout as blockexchange.compress_data
    local bytes = part.to_bytes(data)
    assert(#bytes == 8 * 4)

    -- compressed schemapart format
    Promise.async(function(await)
        local schemapart = await(blockexchange.create_schemapart(data, {x=0, y=0, z=0}, "uid"))
        local p3 = part.from_schemapart(schemapart)
        _, changed = part.diff(p, p3)
        assert(changed == 0)
        assert(p3.param1[1] == 12)
        assert(p3.meta[3].inventory.main[1] == "default:dirt 5")
    end):next(function()
        callback()
    end):catch(function(e)
        error(e, 0)
    end)
end)

mtt.register("sync part: write to the world", function(callback)
    local pos1 = {x=300, y=0, z=300}
    local pos2 = vector.add(pos1, 1)

    blockexchange.emerge("singleplayer", pos1, pos2):next(function()
        -- previous state: node with metadata at index 1
        core.set_node(pos1, { name = "default:stone" })
        core.get_meta(pos1):set_string("infotext", "old")
        local previous = part.from_serialized(blockexchange.serialize_part(pos1, pos2))
        assert(previous.meta[1])

        -- write a part without metadata, with a new node at index 8
        local p = create({"default:dirt"})
        p.names[8] = "default:wood"
        part.write(pos1, p, previous)

        assert(core.get_node(pos1).name == "default:dirt")
        assert(core.get_node(pos2).name == "default:wood")
        assert(core.get_meta(pos1):get_string("infotext") == "")

        local written = part.from_serialized(blockexchange.serialize_part(pos1, pos2))
        local _, changed = part.diff(p, written)
        assert(changed == 0)

        callback()
    end):catch(function(e)
        error(e, 0)
    end)
end)
