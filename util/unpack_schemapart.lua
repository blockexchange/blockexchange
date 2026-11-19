---------
-- schemapart unpacking

--- unpacks (decodes and decompresses) the downloaded schemaparts into data and metadata
-- @param schemapart the downloaded schemapart
-- @return the nodeid/param1/param2 data
-- @return the corresponding metadata
function blockexchange.unpack_schemapart(schemapart)
    local compressed_metadata = core.decode_base64(schemapart.metadata)
    local compressed_data = core.decode_base64(schemapart.data)

    local metadata = core.parse_json(core.decompress(compressed_metadata, "deflate"))
    local data = core.decompress(compressed_data, "deflate")

    return data, metadata
end