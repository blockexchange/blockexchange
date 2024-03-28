---------
-- media api calls

local http, url = ...

--- creates a new mod
-- @param token the token in string format
-- @param mod the mod to create
-- @return a promise with the result
function blockexchange.api.create_media_mod(token, mod)
    return Promise.http(http, url .. "/api/media/mod/" .. mod.name, {
        method = "POST",
        data = mod,
        headers = { "Authorization: " .. token }
    }):next(function(res) return res.json() end)
end

--- creates a new nodedef
-- @param token the token in string format
-- @param mod the nodedef to create
-- @return a promise with the result
function blockexchange.api.create_media_nodedef(token, nodedef)
    return Promise.http(http, url .. "/api/media/nodedef/" .. nodedef.name, {
        method = "POST",
        data = nodedef,
        headers = { "Authorization: " .. token }
    }):next(function(res) return res.json() end)
end

--- creates a new mediafile
-- @param token the token in string format
-- @param mod the mediafile to create
-- @return a promise with the result
function blockexchange.api.create_media_mediafile(token, mediafile)
    return Promise.http(http, url .. "/api/media/mediafile/" .. mediafile.name, {
        method = "POST",
        data = mediafile,
        headers = { "Authorization: " .. token }
    }):next(function(res) return res.json() end)
end
