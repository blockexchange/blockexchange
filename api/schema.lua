---------
-- schema api calls

local http, url = ...

--- creates a new schema
-- @param token the token in string format
-- @param create_schema the new schema as table
-- @return a promise with the result
function blockexchange.api.create_schema(token, create_schema)
  return Promise.http(http, url .. "/api/schema", {
    method = "POST",
    data = create_schema,
    json = true,
    headers = {
      "Authorization: " .. token
    }
  })
end

--- updates the stats of an existing schema
-- @param token the token in string format
-- @param schema_id the schema_id to update
-- @return a promise with the result
function blockexchange.api.update_schema_stats(token, schema_id)
  return Promise.http(http, url .. "/api/schema/" .. schema_id .. "/update", {
    method = "POST",
    data = { done = true },
    json = true,
    timeout = 120,
    headers = {
      "Authorization: " .. token
    }
  })
end

--- updates the screenshot of a schema
-- @param token the token in string format
-- @param schema_id the schema_id to update
-- @return a promise with the result
function blockexchange.api.update_screenshot(token, schema_id)
  return Promise.new(function(resolve, reject)
    local json = minetest.write_json({
      update = true
    })

    local update_url = url .. "/api/schema/" .. schema_id .. "/screenshot/update"

    http.fetch({
      url = update_url,
      extra_headers = {
        "Content-Type: application/json",
        "Authorization: " .. token
      },
      timeout = 120,
      method = "POST",
      data = json
    }, function(res)
      if res.succeeded and res.code == 200 then
        resolve(true)
      else
        reject(res.code or 0)
      end
    end)
  end)
end

--- updates an existing schema
-- @param token the token in string format
-- @param schema the updated schema
-- @return a promise with the result
function blockexchange.api.update_schema(token, schema)
  return Promise.new(function(resolve, reject)
    local json = minetest.write_json(schema)

    http.fetch({
      url = url .. "/api/schema/" .. schema.id,
      extra_headers = {
        "Content-Type: application/json",
        "Authorization: " .. token
      },
      timeout = 10,
      method = "PUT",
      data = json
    }, function(res)
      if res.succeeded and res.code == 200 then
        local updated_schema = minetest.parse_json(res.data)
        resolve(updated_schema)
      else
        reject(res.code or 0)
      end
    end)
  end)
end

--- search for a schema by id
-- @param schema_id the schema_id
-- @return a promise with the result
function blockexchange.api.get_schema_by_id(schema_id)
  return Promise.new(function(resolve, reject)
    http.fetch({
      url = url .. "/api/schema/" .. schema_id,
      timeout = 10
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

--- search for a schema by username and schemaname
-- @param username the username
-- @param schemaname the name of the schema
-- @param download true/false to count as additional download in the stats
-- @return a promise with the result
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
      timeout = 10
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
