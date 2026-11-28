local sync = blockexchange.sync

local schema = {
    uid = "0b9a6b2e-5a0e-4d7f-9a43-0e7c2d3b1a00",
    name = "sync_test",
    user_uid = "1c2d3e4f-0000-0000-0000-000000000000",
    mtime = 1000
}

local function create_entry()
    return sync.create({
        schema = schema,
        owner = "Testuser",
        playername = "singleplayer",
        -- 40x20x17 nodes: 3x2x2 parts
        pos1 = {x=100, y=0, z=200},
        pos2 = {x=139, y=19, z=216}
    })
end

mtt.register("sync store: entries and lookup", function(callback)
    sync.clear()

    local entry = create_entry()
    assert(entry.id and #entry.id == 8)
    assert(entry.schema_uid == schema.uid)
    assert(entry.owner_uid == schema.user_uid)
    assert(entry.pulled_mtime == 1000)
    assert(entry.state == "ok")
    assert(not entry.autosave)

    assert(sync.get(entry.id) == entry)
    assert(sync.get_at({x=100, y=0, z=200}) == entry)
    assert(sync.get_at({x=139, y=19, z=216}) == entry)
    assert(not sync.get_at({x=140, y=0, z=200}))
    assert(#sync.get_in_area({x=0, y=0, z=0}, {x=100, y=0, z=200}) == 1)
    assert(#sync.get_in_area({x=0, y=0, z=0}, {x=99, y=0, z=200}) == 0)

    -- persistence
    sync.load()
    local loaded = sync.get(entry.id)
    assert(loaded and loaded ~= entry)
    assert(vector.equals(loaded.pos1, entry.pos1))
    assert(sync.get_at({x=120, y=10, z=210}).id == entry.id)

    sync.remove(entry.id)
    assert(not sync.get(entry.id))
    assert(not sync.get_at({x=100, y=0, z=200}))
    assert(#sync.list() == 0)

    callback()
end)

mtt.register("sync store: part offsets and dirty tracking", function(callback)
    sync.clear()
    local entry = create_entry()

    assert(vector.equals(sync.get_part_offset(entry, {x=100, y=0, z=200}), {x=0, y=0, z=0}))
    assert(vector.equals(sync.get_part_offset(entry, {x=133, y=17, z=216}), {x=32, y=16, z=16}))

    -- last part on each axis is clipped
    local p1, p2 = sync.get_part_bounds(entry, {x=32, y=16, z=16})
    assert(vector.equals(p1, {x=132, y=16, z=216}))
    assert(vector.equals(p2, {x=139, y=19, z=216}))

    assert(sync.parse_offset_key(sync.offset_key({x=16, y=0, z=32})).z == 32)
    assert(not sync.parse_offset_key("foo"))

    -- single node
    assert(sync.mark_dirty(entry, {x=101, y=1, z=201}))
    assert(not sync.mark_dirty(entry, {x=102, y=2, z=202}))
    assert(sync.is_dirty(entry, {x=0, y=0, z=0}))
    assert(sync.count_dirty(entry) == 1)

    -- range across part borders, partly outside of the entry
    assert(sync.mark_dirty(entry, {x=90, y=0, z=200}, {x=117, y=0, z=200}))
    assert(sync.count_dirty(entry) == 2)
    assert(sync.is_dirty(entry, {x=16, y=0, z=0}))

    -- outside of the entry
    assert(not sync.mark_dirty(entry, {x=0, y=0, z=0}, {x=10, y=10, z=10}))
    assert(sync.count_dirty(entry) == 2)

    sync.clear_dirty(entry, {x=0, y=0, z=0})
    local offsets = sync.get_dirty_offsets(entry)
    assert(#offsets == 1 and vector.equals(offsets[1], {x=16, y=0, z=0}))

    -- dirty flags are persisted
    sync.save()
    sync.load()
    assert(sync.is_dirty(sync.get(entry.id), {x=16, y=0, z=0}))

    callback()
end)

mtt.register("sync store: baseline", function(callback)
    sync.clear()
    local entry = create_entry()

    -- create a real schemapart from the map
    local pos1, pos2 = sync.get_part_bounds(entry, {x=16, y=0, z=0})
    core.set_node(pos1, { name = "default:stone" })
    local data = blockexchange.serialize_part(pos1, pos2)

    Promise.async(function(await)
        local schemapart = await(blockexchange.create_schemapart(data, {x=16, y=0, z=0}, entry.schema_uid))
        schemapart.mtime = 1234

        assert(not sync.get_baseline(entry, {x=16, y=0, z=0}))
        sync.set_baseline(entry, schemapart)

        local baseline = sync.get_baseline(entry, {x=16, y=0, z=0})
        assert(baseline)
        assert(baseline.data == schemapart.data)
        assert(baseline.metadata == schemapart.metadata)
        assert(baseline.mtime == 1234)
        assert(baseline.offset_x == 16)

        local node_data = blockexchange.unpack_schemapart(baseline)
        assert(#node_data > 0)

        local list = sync.list_baselines(entry)
        assert(#list == 1 and vector.equals(list[1], {x=16, y=0, z=0}))

        -- invalid offsets are rejected
        local ok = pcall(sync.set_baseline, entry, { offset_x = 3, offset_y = 0, offset_z = 0 })
        assert(not ok)
        ok = pcall(sync.set_baseline, entry, { offset_x = 48, offset_y = 0, offset_z = 0 })
        assert(not ok)

        sync.remove_baseline(entry, {x=16, y=0, z=0})
        assert(not sync.get_baseline(entry, {x=16, y=0, z=0}))

        -- entry removal deletes the baseline directory
        sync.set_baseline(entry, schemapart)
        sync.remove(entry.id)
        assert(#sync.list_baselines(entry) == 0)
    end):next(function()
        callback()
    end):catch(function(e)
        error(e, 0)
    end)
end)
