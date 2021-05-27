
function blockexchange.unpack_schemapart(schemapart)
    local compressed_metadata = minetest.decode_base64(schemapart.metadata)
    local compressed_data = minetest.decode_base64(schemapart.data)

    local metadata = minetest.parse_json(minetest.decompress(compressed_metadata, "deflate"))
    local data = minetest.decompress(compressed_data, "deflate")

    return data, metadata
end