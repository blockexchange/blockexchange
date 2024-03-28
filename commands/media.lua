
function blockexchange.upload_mod_media(token, modname, license, source)
    local modpath = minetest.get_modpath(modname)

    return blockexchange.api.create_media_mod(token, {
        name = modname,
        source = source or "",
        media_license = license
    }):next(function()

        for nodename in pairs(minetest.registered_nodes) do
            local mn = string.gmatch(nodename, "([^:]+)")()
            if mn == modname then
                -- TODO: create nodedef
            end
        end

        for _, foldername in ipairs({"textures", "models"}) do
            local texturepath = modpath .. "/" .. foldername
            local dir_list = minetest.get_dir_list(texturepath)
            for _, filename in pairs(dir_list) do
                -- TODO: texturepath .. "/" .. filename
            end
        end

        return { nodedefs = 0, mediafiles = 0, size = 0 }
    end)
end