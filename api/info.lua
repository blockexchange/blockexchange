---------
-- info api calls

local http, url = ...

--- returns the blockexchange info data (version, etc)
-- @return a promise with the result (fields: api_version_major, api_version_minor, name, owner)
function blockexchange.api.get_info()
  return Promise.json(http, url .. "/api/info")
end
