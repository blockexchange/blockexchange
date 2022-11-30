
-- 2x2x2
local pos1 = {x=0,y=0,z=0}
local pos2 = vector.add(pos1, 1)

mtt.emerge_area(pos1, pos2)

mtt.register("serialize and modify", function(callback)

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
    local compressed_data = blockexchange.compress_data(data)
    local compressed_metadata = blockexchange.compress_metadata(data)

    -- decompress and parse
    local data2 = minetest.decompress(compressed_data, "deflate")
    local metadata2 = minetest.parse_json(minetest.decompress(compressed_metadata, "deflate"))

    -- place into world
    blockexchange.deserialize_part(pos1, pos2, data2, metadata2)

    -- verify
    local node = minetest.get_node(pos1)
    assert(node.name == "default:mese")

    callback()
end)

mtt.register("serialize unknown node (placeholder placement)", function(callback)

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
    local compressed_data = blockexchange.compress_data(data)
    local compressed_metadata = blockexchange.compress_metadata(data)

    -- decompress and parse
    local data2 = minetest.decompress(compressed_data, "deflate")
    local metadata2 = minetest.parse_json(minetest.decompress(compressed_metadata, "deflate"))

    -- place into world
    blockexchange.deserialize_part(pos1, pos2, data2, metadata2)

    -- verify
    local node = minetest.get_node(pos1)
    assert(node.name == "blockexchange:placeholder")

    local meta = minetest.get_meta(pos1)
    assert(meta:get_string("original_nodename") == "unknown:node")

    callback()
end)

mtt.register("serialize placeholder to proper node", function(callback)

    -- set placeholder
    minetest.set_node(pos1, {name="blockexchange:placeholder"})
    blockexchange.placeholder_populate(pos1, "default:mese", {
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
    assert(not data.node_mapping["blockexchange:placeholder"])

    -- compress
    local compressed_data = blockexchange.compress_data(data)
    local compressed_metadata = blockexchange.compress_metadata(data)

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

    callback()
end)