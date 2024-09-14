local http, url = ...

local function response_handler(res)
  if res.code >= 200 and res.code < 300 then
      return res.json()
  else
      return Promise.rejected("unexpected http error: " .. (res.code or 0))
  end
end

function blockexchange.api.create_schemamods(token, schema_uid, mod_names)
  return Promise.http(http, url .. "/api/schema/" .. schema_uid .. "/mods", {
    method = "POST",
    data = mod_names,
    headers = {
      "Content-Type: application/json",
      "Authorization: " .. token
    }
  })
end

function blockexchange.api.get_schemamods(schema_uid)
  return Promise.http(http, url .. "/api/schema/" .. schema_uid .. "/mods"):next(response_handler)
end
