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
    headers = {
      "Authorization: " .. token
    }
  }):next(function(res) return res.json() end)
end

--- updates the stats of an existing schema
-- @param token the token in string format
-- @param schema_uid the schema_uid to update
-- @return a promise with the result
function blockexchange.api.update_schema_stats(token, schema_uid)
  return Promise.http(http, url .. "/api/schema/" .. schema_uid .. "/update", {
    method = "POST",
    data = { done = true },
    timeout = 120,
    headers = {
      "Authorization: " .. token
    }
  }):next(function(res) return res.json() end)
end

--- updates the screenshot of a schema
-- @param token the token in string format
-- @param schema_uid the schema_uid to update
-- @return a promise with the result
function blockexchange.api.update_screenshot(token, schema_uid)
  return Promise.new(function(resolve, reject)
    local json = minetest.write_json({
      update = true
    })

    local update_url = url .. "/api/schema/" .. schema_uid .. "/screenshot/update"

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
      url = url .. "/api/schema/" .. schema.uid,
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

--- search for a schema by uid
-- @param schema_uid the schema_uid
-- @return a promise with the result
function blockexchange.api.get_schema_by_uid(schema_uid)
  return Promise.http(http, url .. "/api/schema/" .. schema_uid):next(function(res)
    if res.code == 200 then
      return res.json()
    elseif res.code == 404 then
      return nil
    else
      return Promise.rejected("unexpected http error")
    end
  end)
end

--- search for a schema by username and schemaname
-- @param username the username
-- @param schemaname the name of the schema
-- @param download true/false to count as additional download in the stats
-- @return a promise with the result
function blockexchange.api.get_schema_by_name(username, schemaname, download)
  local schema_url = url .. "/api/search/schema/byname/" .. username .. "/" .. schemaname
    if download then
      -- increment download counter
      schema_url = schema_url .. "?download=true"
    end
  return Promise.http(http, schema_url):next(function(res)
    if res.code == 200 then
      return res.json()
    elseif res.code == 404 then
      return nil
    else
      return Promise.rejected("unexpected http error")
    end
  end)
end
