local http, url = ...

function blockexchange.api.create_schemamods(token, schema_id, mod_names, callback, err_callback)
  local json = minetest.write_json(mod_names);

  http.fetch({
    url = url .. "/api/schema/" .. schema_id .. "/mods",
    extra_headers = {
      "Content-Type: application/json",
      "Authorization: " .. token
    },
    timeout = 5,
    post_data = json
  }, function(res)
    if res.succeeded and res.code == 200 then
      callback(true)
		elseif type(err_callback) == "function" then
      err_callback(res.code or 0)
    end
  end)
end

function blockexchange.api.get_schemamods(schema_id, callback, err_callback)
  http.fetch({
    url = url .. "/api/schema/" .. schema_id .. "/mods",
    timeout = 5
  }, function(res)
    if res.succeeded and res.code == 200 then
      local mod_names = minetest.parse_json(res.data)
      callback(mod_names)
		elseif type(err_callback) == "function" then
      err_callback(res.code or 0)
    end
  end)
end
