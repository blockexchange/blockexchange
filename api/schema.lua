---------
-- schema api calls

local http, url = ...

--- creates a new schema
-- @param token the token in string format
-- @param create_schema the new schema as table
-- @return a promise with the result
function blockexchange.api.create_schema(token, create_schema)
  return Promise.json(http, url .. "/api/schema", {
    method = "POST",
    data = create_schema,
    headers = {
      "Authorization: " .. token
    }
  })
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
  }):next(function(res)
    if res.code == 200 or res.code == 204 then
      return true
    else
      return Promise.rejected("unexpected http code: " .. res.code)
    end
  end)
end

local function response_handler(res)
  if res.code == 200 then
    return res.json()
  elseif res.code == 404 then
    return nil
  else
    return Promise.rejected("unexpected http code: " .. res.code)
  end
end

--- search for a schema by uid
-- @param schema_uid the schema_uid
-- @return a promise with the result
function blockexchange.api.get_schema_by_uid(schema_uid, download)
  local schema_url = url .. "/api/schema/" .. schema_uid
  if download then
    -- increment download counter
    schema_url = schema_url .. "?download=true"
  end

  return Promise.http(http, schema_url):next(response_handler)
end

--- search for a schema by username and schemaname
-- @param user_name the username
-- @param schema_name the name of the schema
-- @param download true/false to count as additional download in the stats
-- @return a promise with the result
function blockexchange.api.get_schema_by_name(user_name, schema_name, download)
  return Promise.http(http, url .. "/api/search/schema", {
    method = "POST",
    data = {
      user_name = user_name,
      schema_name = schema_name
    }
  }):next(response_handler):next(function(search_result)
    -- extract uid
    if #search_result ~= 1 then
      -- no results, resolve with nil-promise
      return nil
    else
      -- download schematic
      return blockexchange.api.get_schema_by_uid(search_result[1].schema.uid, download)
    end
  end)
end
