---------
-- info api calls

local http, url = ...

--- returns the blockexchange info data (version, etc)
-- @return a table with the fields: api_version_major, api_version_minor, name, owner
function blockexchange.api.get_info()
  return Promise.new(function(resolve, reject)
    http.fetch({
      url = url .. "/api/info",
      timeout = 5
    }, function(res)
      if res.succeeded and res.code == 200 then
        local info = minetest.parse_json(res.data)
        resolve(info)
      else
        reject(res.code or 0)
      end
    end)
  end)
end
