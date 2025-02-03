local http, url = ...

function blockexchange.api.create_schemamods(token, schema_uid, mod_names)
  return Promise.json(http, url .. "/api/schema/" .. schema_uid .. "/mods", {
    method = "POST",
    data = mod_names,
    headers = {
      "Authorization: " .. token
    }
  })
end

function blockexchange.api.get_schemamods(schema_uid)
  return Promise.json(http, url .. "/api/schema/" .. schema_uid .. "/mods")
end
