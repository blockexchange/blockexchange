---------
-- media api calls

local http, url = ...

local function response_handler(res)
    if res.code == 200 then
        return res.json()
    else
        return Promise.rejected("unexpected http error")
    end
end

--- creates a new mod
-- @param token the token in string format
-- @param mod the mod to create
-- @return a promise with the result
function blockexchange.api.create_media_mod(token, mod)
    return Promise.http(http, url .. "/api/media/mod/" .. mod.name, {
        method = "POST",
        data = mod,
        headers = { "Authorization: " .. token }
    }):next(response_handler)
end

--- creates or updates nodedefs
-- @param token the token in string format
-- @param nodedefs the nodedefs to create
-- @return a promise with the result
function blockexchange.api.create_media_nodedefs(token, nodedefs)
    return Promise.http(http, url .. "/api/media/nodedef", {
        method = "POST",
        data = nodedefs,
        headers = { "Authorization: " .. token }
    }):next(response_handler)
end

--- creates or updates mediafiles
-- @param token the token in string format
-- @param mediafiles the mediafiles to create
-- @return a promise with the result
function blockexchange.api.create_media_mediafiles(token, mediafiles)
    return Promise.http(http, url .. "/api/media/mediafile", {
        method = "POST",
        data = mediafiles,
        headers = { "Authorization: " .. token }
    }):next(response_handler)
end
