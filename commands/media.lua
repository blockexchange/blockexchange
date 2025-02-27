
function blockexchange.upload_mod_media(token, mod_name, license, source)
    local modpath = minetest.get_modpath(mod_name)

    return blockexchange.api.create_media_mod(token, {
        name = mod_name,
        source = source or "",
        media_license = license
    }):next(function()
        local stats = { nodedefs = 0, mediafiles = 0, size = 0 }

        local nodedefs = {}
        for nodename, def in pairs(minetest.registered_nodes) do
            local mn = string.gmatch(nodename, "([^:]+)")()
            if mn == mod_name then
                stats.nodedefs = stats.nodedefs + 1
                table.insert(nodedefs, {
                    name = nodename,
                    mod_name = mod_name,
                    definition = minetest.write_json({
                        name = nodename,
                        drawtype = def.drawtype,
                        paramtype = def.paramtype,
                        paramtype2 = def.paramtype2,
                        light_source = def.light_source,
                        mesh = def.mesh,
                        tiles = def.tiles,
                        node_box = def.node_box,
                        connects_to = def.connects_to,
                        groups = def.groups
                    })
                })
            end
        end
        local nodedef_promise = blockexchange.api.create_media_nodedefs(token, nodedefs)

        local mediafiles = {}
        for _, foldername in ipairs({"textures", "models"}) do
            local texturepath = modpath .. "/" .. foldername
            local dir_list = minetest.get_dir_list(texturepath)
            for _, filename in pairs(dir_list) do
                local infile = io.open(texturepath .. "/" .. filename, "rb")
                local data = infile:read("*a")
                infile:close()

                stats.mediafiles = stats.mediafiles + 1
                stats.size = stats.size + #data
                table.insert(mediafiles, {
                    name = filename,
                    mod_name = mod_name,
                    data = minetest.encode_base64(data)
                })
            end
        end
        local mediafile_promise = blockexchange.api.create_media_mediafiles(token, mediafiles)

        return Promise.all(nodedef_promise, mediafile_promise):next(function()
            return stats
        end)
    end)
end


minetest.register_chatcommand("bx_upload_media", {
    params = "<modname> <license>",
    privs = { blockexchange = true },
    description = "Uploads the media of the given mod and license",
    func = function(name, param)
        local _, _, modname, license = string.find(param, "^([^%s]+)%s+(.*)$")

        if not modname or not license then
            return true, "please specify a modname and a license"
        end

        local modpath = minetest.get_modpath(modname)
        if not modpath then
            return true, "mod '" .. modname .. "' not found"
        end

        local player_settings = blockexchange.get_player_settings(name)
        if not player_settings.token then
            return true, "please login first to upload media"
        end

        blockexchange.upload_mod_media(player_settings.token, modname, license):next(function(stats)
            minetest.chat_send_player(name, "[blockexchange] uploaded " .. stats.nodedefs .. " node-definitions and " ..
                stats.mediafiles .. " mediafiles with " .. stats.size .. " bytes")
        end):catch(function(e)
            minetest.chat_send_player(name, "[blockexchange] and error occured: " .. dump(e))
        end)

        return true, "uploading media from mod '" .. modname .. "' with license '" .. license .. "'"
    end
})
