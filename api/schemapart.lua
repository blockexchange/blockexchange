local http, url = ...

function blockexchange.api.create_schemapart(token, schema_id, pos, data, callback, err_callback)

	local metadata = minetest.write_json({
		node_mapping = data.node_mapping,
		size = data.size,
		metadata = data.metadata
	})

	local compressed_metadata = minetest.compress(metadata, "deflate")
	local compressed_data = minetest.compress(data.serialized_data, "deflate")

  local json = minetest.write_json({
    schema_id = schema_id,
    offset_x = pos.x,
    offset_y = pos.y,
    offset_z = pos.z,
    data = minetest.encode_base64(compressed_data),
		metadata = minetest.encode_base64(compressed_metadata)
  });

  http.fetch({
    url = url .. "/api/schemapart",
    extra_headers = {
      "Content-Type: application/json",
      "Authorization: " .. token
    },
    timeout = 5,
		method = "POST",
    post_data = json
  }, function(res)
    if res.succeeded and res.code == 200 then
      callback(true)
		elseif type(err_callback) == "function" then
      err_callback(res.code or 0)
    end
  end)
end

function blockexchange.api.remove_schemapart(token, schema_id, pos, callback, err_callback)
  http.fetch({
    url = url .. "/api/schemapart/" .. schema_id .. "/" .. pos.x .. "/" .. pos.y .. "/" .. pos.z,
    extra_headers = {
      "Content-Type: application/json",
      "Authorization: " .. token
    },
    timeout = 5,
		method = "DELETE"
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
			-- schema part found
      local schemapart = minetest.parse_json(res.data)
      callback(schemapart)
		elseif (res.succeeded and res.code == 204) or (res.code == 404) then
			-- air only part
			callback(nil)
		elseif type(err_callback) == "function" then
      err_callback(res.code or 0)
    end
  end)
end
