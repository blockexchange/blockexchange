---------
-- schema api calls

local http, url = ...

--- creates a new schema
-- @param token the token in string format
-- @param create_schema the new schema as table
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

--- updates the stats of an existing schema
-- @param token the token in string format
-- @param schema_id the schema_id to update
-- @param is_initial initial/first time
function blockexchange.api.update_schema(token, schema_id, is_initial)
  return Promise.new(function(resolve, reject)
    local json = minetest.write_json({
      done = true
    })

    local update_url = url .. "/api/schema/" .. schema_id .. "/update"

    if is_initial then
      update_url = update_url .. "?initial=true"
    end

    http.fetch({
      url = update_url,
      extra_headers = {
        "Content-Type: application/json",
        "Authorization: " .. token
      },
      timeout = 120,
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
