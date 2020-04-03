
-- localize variables to prevent tampering after mod load
local http = blockexchange.http
local url = blockexchange.url

function blockexchange.api.create_schemapart(token, schema_id, pos, data, callback, err_callback)
  local json = minetest.write_json({
    schema_id = schema_id,
    offset_x = pos.x,
    offset_y = pos.y,
    offset_z = pos.z,
    data = data
  });

  http.fetch({
    url = url .. "/api/schemapart",
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

function blockexchange.api.get_schemapart(schema_id, pos, callback, err_callback)
  http.fetch({
    url = url .. "/api/schemapart/" .. schema_id .. "/" .. pos.x .. "/" .. pos.y .. "/" .. pos.z,
    timeout = 5
  }, function(res)
    if res.succeeded and res.code == 200 then
      local schemapart = minetest.parse_json(res.data)
      callback(schemapart)
		elseif type(err_callback) == "function" then
      err_callback(res.code or 0)
    end
  end)
end
