
function blockexchange.upload_mod_media(token, mod_name)
    local modpath = core.get_modpath(mod_name)

    return Promise.async(function(await)
        local stats = { nodedefs = 0, mediafiles = 0, size = 0 }

        local nodedefs = {}
        for nodename, def in pairs(core.registered_nodes) do
            local mn = string.gmatch(nodename, "([^:]+)")()
            if mn == mod_name then
                stats.nodedefs = stats.nodedefs + 1
                local exported_def = {
                    name = nodename,
                    drawtype = def.drawtype,
                    paramtype = def.paramtype,
                    paramtype2 = def.paramtype2,
                    light_source = def.light_source,
                    mesh = def.mesh,
                    tiles = def.tiles,
                    special_tiles = def.special_tiles,
                    overlay_tiles = def.overlay_tiles,
                    use_texture_alpha = def.use_texture_alpha,
                    visual_scale = def.visual_scale,
                    color = def.color,
                    palette = def.palette,
                    waving = def.waving,
                    node_box = def.node_box,
                    connects_to = def.connects_to,
                    connect_sides = def.connect_sides,
                    walkable = def.walkable,
                    groups = def.groups
                }
                if def.drawtype == "liquid" or def.drawtype == "flowingliquid" then
                    exported_def.post_effect_color = def.post_effect_color
                    exported_def.liquid_alternative_source = def.liquid_alternative_source
                    exported_def.liquid_alternative_flowing = def.liquid_alternative_flowing
                    exported_def.liquid_range = def.liquid_range
                end

                table.insert(nodedefs, {
                    name = nodename,
                    mod_name = mod_name,
                    definition = core.write_json(exported_def)
                })
            end
        end
        local nodedef_promise = blockexchange.api.create_media_nodedefs(token, nodedefs)

        local mediafiles = {}
        for _, foldername in ipairs({"textures", "models"}) do
            local texturepath = modpath .. "/" .. foldername
            local dir_list = core.get_dir_list(texturepath)
            for _, filename in pairs(dir_list) do
                local infile = io.open(texturepath .. "/" .. filename, "rb")
                local data = infile:read("*a")
                infile:close()

                stats.mediafiles = stats.mediafiles + 1
                stats.size = stats.size + #data
                table.insert(mediafiles, {
                    name = filename,
                    mod_name = mod_name,
                    data = core.encode_base64(data)
                })
            end
        end
        local mediafile_promise = blockexchange.api.create_media_mediafiles(token, mediafiles)

        -- both uploads run in parallel
        local _, err = await(Promise.all(nodedef_promise, mediafile_promise))
        if err then
            error("media upload error: " .. tostring(err), 0)
        end

        return stats
    end)
end


core.register_chatcommand("bx_upload_media", {
    params = "<modname>",
    privs = { blockexchange = true },
    description = "Uploads the media of the given mod",
    func = function(name, modname)
        if not modname then
            return true, "please specify a modname"
        end

        local modpath = core.get_modpath(modname)
        if not modpath then
            return true, "mod '" .. modname .. "' not found"
        end

        local player_settings = blockexchange.get_player_settings(name)
        if not player_settings.token then
            return true, "please login first to upload media"
        end

        blockexchange.upload_mod_media(player_settings.token, modname):next(function(stats)
            core.chat_send_player(name, "[blockexchange] uploaded " .. stats.nodedefs .. " node-definitions and " ..
                stats.mediafiles .. " mediafiles with " .. stats.size .. " bytes")
        end):catch(function(e)
            core.chat_send_player(name, "[blockexchange] and error occured: " .. dump(e))
        end)

        return true, "uploading media from mod '" .. modname .. "'"
    end
})
