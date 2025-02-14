
function blockexchange.create_schemapart(data, pos, schema_uid)
    return {
        schema_uid = schema_uid,
        offset_x = pos.x,
        offset_y = pos.y,
        offset_z = pos.z,
        data = minetest.encode_base64(blockexchange.compress_data(data)),
        metadata = minetest.encode_base64(blockexchange.compress_metadata(data))
    }
end