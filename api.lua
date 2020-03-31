
-- localize variables to prevent tampering after mod load
local http = blockexchange.http
local url = blockexchange.url

function blockexchange.create_schema(pos1, pos2, description, tags, callback, err_callback)
  local json = minetest.write_json({
    size_x = pos2.x - pos1.x,
    size_y = pos2.y - pos1.y,
    size_z = pos2.z - pos1.z,
    part_length = 10,
		description = description,
		tags = tags
  });

  http.fetch({
    url = url .. "/api/schema",
    extra_headers = { "Content-Type: application/json" },
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

function blockexchange.finalize_schema(schema_id, modname_count, callback, err_callback)
	local json = minetest.write_json({
		modname_count = modname_count
	})

  http.fetch({
    url = url .. "/api/schema/" .. schema_id .. "/complete",
    extra_headers = { "Content-Type: application/json" },
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

function blockexchange.create_schemapart(schema_id, pos, data, callback, err_callback)
  local json = minetest.write_json({
    schema_id = schema_id,
    offset_x = pos.x,
    offset_y = pos.y,
    offset_z = pos.z,
    data = data
  });

  http.fetch({
    url = url .. "/api/schemapart",
    extra_headers = { "Content-Type: application/json" },
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

function blockexchange.get_schema(schema_id, callback, err_callback)
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

function blockexchange.get_schemapart(schema_id, pos, callback, err_callback)
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
