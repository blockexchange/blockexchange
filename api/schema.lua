
-- localize variables to prevent tampering after mod load
local http = blockexchange.http
local url = blockexchange.url

function blockexchange.api.create_schema(token, pos1, pos2, description, tags, callback, err_callback)
  local json = minetest.write_json({
    size_x = pos2.x - pos1.x,
    size_y = pos2.y - pos1.y,
    size_z = pos2.z - pos1.z,
    part_length = blockexchange.part_length,
		description = description,
		tags = tags
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

function blockexchange.api.finalize_schema(token, schema_id, node_count, callback, err_callback)
	local json = minetest.write_json({
		node_count = node_count
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

function blockexchange.api.get_schema(schema_uid, callback, err_callback)
  http.fetch({
    url = url .. "/api/schema/" .. schema_uid,
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