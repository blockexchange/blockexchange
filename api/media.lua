---------
-- media api calls

local http, url = ...

--- creates a new mod
-- @param token the token in string format
-- @param mod the mod to create
-- @return a promise with the result
function blockexchange.api.create_media_mod(token, mod)
    return Promise.json(http, url .. "/api/media/mod/" .. mod.name, {
        method = "POST",
        data = mod,
        headers = { "Authorization: " .. token }
    })
end

--- creates or updates nodedefs
-- @param token the token in string format
-- @param nodedefs the nodedefs to create
-- @return a promise with the result
function blockexchange.api.create_media_nodedefs(token, nodedefs)
    return Promise.json(http, url .. "/api/media/nodedef", {
        method = "POST",
        data = nodedefs,
        headers = { "Authorization: " .. token }
    })
end

--- creates or updates mediafiles
-- @param token the token in string format
-- @param mediafiles the mediafiles to create
-- @return a promise with the result
function blockexchange.api.create_media_mediafiles(token, mediafiles)
    return Promise.json(http, url .. "/api/media/mediafile", {
        method = "POST",
        data = mediafiles,
        headers = { "Authorization: " .. token }
    })
end
