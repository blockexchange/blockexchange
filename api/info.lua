---------
-- info api calls

local http, url = ...

--- returns the blockexchange info data (version, etc)
-- @return a promise with the result (fields: api_version_major, api_version_minor, name, owner)
function blockexchange.api.get_info()
  return Promise.json(http, url .. "/api/info")
end


--- checks if the server supports schemapart chunks with 5x5x5 parts (api version 1.2 and up)
-- the result is cached for 5 minutes, errors resolve with false (sequential download)
-- @return a promise resolving with true or false
blockexchange.api.supports_chunks = Promise.cache(300, function()
  return blockexchange.api.get_info():next(function(info)
    return info.api_version_major == 1 and (info.api_version_minor or 0) >= 2
  end):catch(function(err)
    core.log("warning", "[blockexchange] api version check failed, using sequential download: " .. dump(err))
    return false
  end)
end)
