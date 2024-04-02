local http, url = ...

function blockexchange.api.create_schemamods(token, schema_uid, mod_names)
  return Promise.http(http, url .. "/api/schema/" .. schema_uid .. "/mods", {
    method = "POST",
    data = mod_names,
    headers = { "Authorization: " .. token }
  }):next(function(res) return res.code == 200 end)
end

function blockexchange.api.get_schemamods(schema_uid)
  return Promise.http(http, url .. "/api/schema/" .. schema_uid .. "/mods")
  :next(function(res)
    if res.code == 200 then
      return res.json()
    else
      return Promise.rejected("http error: " .. res.code)
    end
  end)
end
