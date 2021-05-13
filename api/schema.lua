local http, url = ...

function blockexchange.api.create_schema(token, create_schema)
  return Promise.new(function(resolve, reject)
    local json = minetest.write_json(create_schema);
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
        resolve(schema)
      else
        reject(res.code or 0)
      end
    end)
  end)
end

function blockexchange.api.finalize_schema(token, schema_id)
  return Promise.new(function(resolve, reject)
    local json = minetest.write_json({
      done = true
    })

    http.fetch({
      url = url .. "/api/schema/" .. schema_id .. "/update",
      extra_headers = {
        "Content-Type: application/json",
        "Authorization: " .. token
      },
      timeout = 5,
      post_data = json
    }, function(res)
      if res.succeeded and res.code == 200 then
        resolve(true)
      else
        reject(res.code or 0)
      end
    end)
  end)
end

function blockexchange.api.get_schema_by_id(schema_id)
  return Promise.new(function(resolve, reject)
    http.fetch({
      url = url .. "/api/schema/" .. schema_id,
      timeout = 5
    }, function(res)
      if res.succeeded and res.code == 200 then
        local schema = minetest.parse_json(res.data)
        resolve(schema)
      else
        reject(res.code or 0)
      end
    end)
  end)
end

function blockexchange.api.get_schema_by_name(username, schemaname, download)
  return Promise.new(function(resolve, reject)
      -- replace spaces with %20
    local schema_url = url .. "/api/search/schema/byname/" .. username .. "/" .. schemaname:gsub(" ", '%%20')
    if download then
      -- increment download counter
      schema_url = schema_url .. "?download=true"
    end

    http.fetch({
      url = schema_url,
      timeout = 5
    }, function(res)
      if res.succeeded and res.code == 200 then
        local schema = minetest.parse_json(res.data)
        resolve(schema)
      else
        reject(res.code or 0)
      end
    end)
  end)
end
