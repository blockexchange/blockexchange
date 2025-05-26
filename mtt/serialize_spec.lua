
-- 2x2x2
local pos1 = {x=0,y=0,z=0}
local pos2 = vector.add(pos1, 1)

mtt.emerge_area(pos1, pos2)

mtt.benchmark("blockexchange.serialize_part", function(callback, iterations)
    for _=1,iterations do
        local data, node_count = blockexchange.serialize_part(pos1, pos2)
        assert(data)
        assert(node_count)
        assert(#data.node_ids == 8)
    end
    callback()
end)

mtt.register("serialize and modify", Promise.asyncify(function(await)
    -- serialize
    local data, node_count = blockexchange.serialize_part(pos1, pos2)
    assert(data)
    assert(node_count)
    assert(#data.node_ids == 8)

    -- set pos1 to meseblock
    local mese_id = minetest.get_content_id("default:mese")
    data.node_ids[1] = mese_id
    data.node_mapping["default:mese"] = mese_id

    -- compress
    local compressed_data = await(blockexchange.compress_data(data))
    local compressed_metadata = await(blockexchange.compress_metadata(data))

    -- decompress and parse
    local data2 = minetest.decompress(compressed_data, "deflate")
    local metadata2 = minetest.parse_json(minetest.decompress(compressed_metadata, "deflate"))

    -- place into world
    blockexchange.deserialize_part(pos1, pos2, data2, metadata2)

    -- verify
    local node = minetest.get_node(pos1)
    assert(node.name == "default:mese")
end))

mtt.register("serialize unknown node (placeholder placement)", Promise.asyncify(function(await)

    -- serialize
    local data, node_count = blockexchange.serialize_part(pos1, pos2)
    assert(data)
    assert(node_count)
    assert(#data.node_ids == 8)

    -- set pos1 to unknown node
    local unknown_id = 666
    data.node_ids[1] = unknown_id
    data.node_mapping["unknown:node"] = unknown_id

    -- compress
    local compressed_data = await(blockexchange.compress_data(data))
    local compressed_metadata = await(blockexchange.compress_metadata(data))

    -- decompress and parse
    local data2 = minetest.decompress(compressed_data, "deflate")
    local metadata2 = minetest.parse_json(minetest.decompress(compressed_metadata, "deflate"))

    -- place into world
    blockexchange.deserialize_part(pos1, pos2, data2, metadata2)

    -- verify
    local node = minetest.get_node(pos1)
    assert(node.name == "placeholder:placeholder")

    local meta = minetest.get_meta(pos1)
    assert(meta:get_string("original_nodename") == "unknown:node")

end))

mtt.register("serialize placeholder to proper node", Promise.asyncify(function(await)

    -- set placeholder
    placeholder.place(pos1, {name="default:mese"}, {
        inventory = {},
        fields = {
            x = "y"
        }
    })

    -- serialize
    local data, node_count = blockexchange.serialize_part(pos1, pos2)
    assert(data)
    assert(node_count)
    assert(#data.node_ids == 8)
    assert(not data.node_mapping["placeholder:placeholder"])

    -- compress
    local compressed_data = await(blockexchange.compress_data(data))
    local compressed_metadata = await(blockexchange.compress_metadata(data))

    -- decompress and parse
    local data2 = minetest.decompress(compressed_data, "deflate")
    local metadata2 = minetest.parse_json(minetest.decompress(compressed_metadata, "deflate"))

    -- place into world
    blockexchange.deserialize_part(pos1, pos2, data2, metadata2)

    -- verify
    local node = minetest.get_node(pos1)
    assert(node.name == "default:mese")

    local meta = minetest.get_meta(pos1)
    assert(meta:get_string("x") == "y")
end))