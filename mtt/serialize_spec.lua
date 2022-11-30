
-- 2x2x2
local pos1 = {x=0,y=0,z=0}
local pos2 = vector.add(pos1, 1)

mtt.emerge_area(pos1, pos2)

mtt.register("serialize", function(callback)

    local data, node_count = blockexchange.serialize_part(pos1, pos2)
    assert(data)
    assert(node_count)
    assert(#data.node_ids == 8)

    blockexchange.deserialize_part(pos1, pos2, data.serialized_data, data)

    callback()
end)