
-- localize variables to prevent tampering after mod load
local http = blockexchange.http
local url = blockexchange.url

function blockexchange.api.create_schema(token, pos1, pos2, name, description, callback, err_callback)
  local json = minetest.write_json({
    size_x = pos2.x - pos1.x + 1,
    size_y = pos2.y - pos1.y + 1,
    size_z = pos2.z - pos1.z + 1,
    part_length = blockexchange.part_length,
		description = description,
		name = name
  });

  http.fetch({
    url = url .. "/api/schema",
    extra_headers = {
      "Content-Type: application/json",
      "Authorization: " .. token
    },
    timeout = 5,
    post_data = json
  }, function(res)
    if res.succeeded and res.code == 200 then
      local schema = minetest.parse_json(res.data)
      callback(schema)
    elseif type(err_callback) == "function" then
      err_callback(res.code or 0)
    end
  end)
end

function blockexchange.api.finalize_schema(token, schema_id, callback, err_callback)
	local json = minetest.write_json({
    done = true
  })

  http.fetch({
    url = url .. "/api/schema/" .. schema_id .. "/complete",
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

function blockexchange.api.get_schema_by_id(schema_id, callback, err_callback)
  http.fetch({
    url = url .. "/api/schema/" .. schema_id,
    timeout = 5
  }, function(res)
    if res.succeeded and res.code == 200 then
      local schema = minetest.parse_json(res.data)
      callback(schema)
		elseif type(err_callback) == "function" then
      err_callback(res.code or 0)
    end
  end)
end

function blockexchange.api.get_schema_by_name(username, schemaname, callback, err_callback)
  http.fetch({
    url = url .. "/api/search/schema/byname/" .. username .. "/" .. schemaname,
    timeout = 5
  }, function(res)
    if res.succeeded and res.code == 200 then
      local schema = minetest.parse_json(res.data)
      callback(schema)
		elseif type(err_callback) == "function" then
      err_callback(res.code or 0)
    end
  end)
end
