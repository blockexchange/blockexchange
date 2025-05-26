
blockexchange.create_schemapart = Promise.asyncify(function(await, data, pos, schema_uid)
    local compressed_data = await(blockexchange.compress_data(data))
    local compressed_metadata = await(blockexchange.compress_metadata(data))

    return {
        schema_uid = schema_uid,
        offset_x = pos.x,
        offset_y = pos.y,
        offset_z = pos.z,
        data = minetest.encode_base64(compressed_data),
        metadata = minetest.encode_base64(compressed_metadata)
    }
end)