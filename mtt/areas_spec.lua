
mtt.register("load, query and save areas", function(callback)
    blockexchange.clear_areas()

    local pos1 = {x=0, y=1, z=2}
    local pos2 = {x=0, y=10, z=20}
    local username = "singleplayer"
    local schema = {
        id = 1,
        mtime = 1000,
        username = "xyz"
    }
    blockexchange.register_area(pos1, pos2, "singleplayer", username, schema)

    local area = blockexchange.get_area({x=-1, y=-1, z=-1})
    assert(not area)

    area = blockexchange.get_area(pos1)
    assert(area)
    assert(vector.equals(area.pos1, pos1))
    assert(vector.equals(area.pos2, pos2))
    assert(area.schema_uid == schema.uid)

    blockexchange.load_areas()
    area = blockexchange.get_area(pos1)
    assert(area)

    callback()
end)