-- test node, only registered if the mtt mod is present
minetest.register_node("blockexchange:media_test_node", {
    description = "blockexchange media test node",
    tiles = { "blockexchange_info.png" },
    groups = { not_in_creative_inventory = 1 }
})

mtt.register("upload_mod_media, collects nodedefs and mediafiles", function(callback)
    local api = blockexchange.api
    local orig_create_mod = api.create_media_mod
    local orig_create_nodedefs = api.create_media_nodedefs
    local orig_create_mediafiles = api.create_media_mediafiles

    local function restore()
        api.create_media_mod = orig_create_mod
        api.create_media_nodedefs = orig_create_nodedefs
        api.create_media_mediafiles = orig_create_mediafiles
    end

    local captured = {}
    api.create_media_mod = function(token, mod)
        captured.mod_token = token
        captured.mod = mod
        return Promise.resolved(mod)
    end
    api.create_media_nodedefs = function(token, nodedefs)
        captured.nodedefs_token = token
        captured.nodedefs = nodedefs
        return Promise.resolved(true)
    end
    api.create_media_mediafiles = function(token, mediafiles)
        captured.mediafiles_token = token
        captured.mediafiles = mediafiles
        return Promise.resolved(true)
    end

    local modpath = minetest.get_modpath("blockexchange")
    local texture_count = #minetest.get_dir_list(modpath .. "/textures", false)
        + #minetest.get_dir_list(modpath .. "/models", false)

    blockexchange.upload_mod_media("my-token", "blockexchange", "CC0"):next(function(stats)
        restore()

        -- mod entry
        assert(captured.mod_token == "my-token")
        assert(captured.mod.name == "blockexchange")
        assert(captured.mod.media_license == "CC0")
        assert(captured.mod.source == "")

        -- nodedefs: only nodes of the given mod
        assert(captured.nodedefs_token == "my-token")
        local found_test_node = false
        for _, nd in ipairs(captured.nodedefs) do
            assert(nd.mod_name == "blockexchange")
            assert(nd.name:sub(1, #"blockexchange:") == "blockexchange:", "foreign node: " .. nd.name)
            if nd.name == "blockexchange:media_test_node" then
                found_test_node = true
                local def = minetest.parse_json(nd.definition)
                assert(def.name == "blockexchange:media_test_node")
                assert(def.tiles[1] == "blockexchange_info.png")
            end
        end
        assert(found_test_node, "test node not found in nodedefs")
        assert(stats.nodedefs == #captured.nodedefs)

        -- mediafiles
        assert(captured.mediafiles_token == "my-token")
        assert(#captured.mediafiles == texture_count)
        assert(stats.mediafiles == texture_count)
        local size = 0
        for _, mf in ipairs(captured.mediafiles) do
            assert(mf.mod_name == "blockexchange")
            assert(type(mf.data) == "string" and #mf.data > 0)
            size = size + #minetest.decode_base64(mf.data)
        end
        assert(stats.size == size)
        assert(stats.size > 0)

        callback()
    end):catch(function(err)
        restore()
        callback(err)
    end)
end)

local function has_permission(token, perm)
    local claims = blockexchange.parse_token(token)
    for _, p in ipairs(claims and claims.permissions or {}) do
        if p == perm then
            return true
        end
    end
    return false
end

mtt.register("upload_mod_media, remote upload", {
    timeout = 60,
    func = function(callback)
        Promise.async(function(await)
            local token, err = await(blockexchange.api.get_token("Testuser", "default"))
            if err then error("get_token error: " .. tostring(err), 0) end

            local stats
            stats, err = await(blockexchange.upload_mod_media(token, "blockexchange", "CC0", "https://example.com"))

            if not has_permission(token, "MEDIA") then
                -- non-admin users are expected to get rejected
                if not err then error("upload succeeded without MEDIA permission", 0) end
                return
            end

            if err then error("upload error: " .. tostring(err), 0) end
            assert(stats.nodedefs > 0)
            assert(stats.mediafiles > 0)
        end):next(function()
            callback()
        end):catch(function(err)
            callback(err)
        end)
    end
})
