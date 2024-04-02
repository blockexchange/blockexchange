local http, url = ...

function blockexchange.api.create_schemamods(token, schema_uid, mod_names)
  return Promise.http(http, url .. "/api/schema/" .. schema_uid .. "/mods", {
    method = "POST",
    data = mod_names,
    headers = { "Authorization: " .. token }
  }):next(function(res) return res.code == 200 end)
end

function blockexchange.api.get_schemamods(schema_uid)
  return Promise.new(function(resolve, reject)
    http.fetch({
      url = url .. "/api/schema/" .. schema_uid .. "/mods",
      timeout = 5
    }, function(res)
      if res.succeeded and res.code == 200 then
        local mod_names = minetest.parse_json(res.data)
        resolve(mod_names)
      else
        reject(res.code or 0)
      end
    end)
  end)
end
