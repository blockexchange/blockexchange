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

--- lets the server recalculate the mod-list from the stored schemaparts
function blockexchange.api.update_schemamods(token, schema_uid)
  return Promise.http(http, url .. "/api/schema/" .. schema_uid .. "/mods/update", {
    method = "POST",
    data = "update",
    headers = {
      "Authorization: " .. token
    }
  }):next(function(res)
    if res.code == 200 or res.code == 204 then
      return true
    else
      return Promise.rejected("unexpected http code: " .. res.code)
    end
  end)
end

function blockexchange.api.get_schemamods(schema_uid)
  return Promise.json(http, url .. "/api/schema/" .. schema_uid .. "/mods")
end
