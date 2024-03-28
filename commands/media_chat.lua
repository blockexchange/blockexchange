
minetest.register_chatcommand("bx_upload_media", {
    params = "<modname> <license>",
    privs = { blockexchange = true },
    description = "Uploads the media of the given mod and license",
    func = blockexchange.api_check_wrapper(function(name, param)
        local _, _, modname, license = string.find(param, "^([^%s]+)%s+(.*)$")

        if not modname or not license then
            return true, "please specify a modname and a license"
        end

        local modpath = minetest.get_modpath(modname)
        if not modpath then
            return true, "mod '" .. modname .. "' not found"
        end

        local token = blockexchange.get_token(name)
        if not token then
            return true, "please login first to upload media"
        end

        blockexchange.upload_mod_media(token, modname, license):next(function(stats)
            minetest.chat_send_player(name, "[blockexchange] uploaded " .. stats.nodedefs .. " node-definitions and " ..
                stats.mediafiles .. " mediafiles with " .. stats.size .. " bytes")
        end):catch(function(e)
            minetest.chat_send_player(name, "[blockexchange] and error occured: " .. dump(e))
        end)

        return true, "uploading media from mod '" .. modname .. "' with license '" .. license .. "'"
    end)
})
