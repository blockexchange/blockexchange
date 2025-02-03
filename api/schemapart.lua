local http, url = ...

function blockexchange.api.create_schemapart(token, data)
  return Promise.json(http, url .. "/api/schemapart", {
    method = "POST",
    data = data,
    headers = {
      "Authorization: " .. token
    }
  })
end

function blockexchange.api.remove_schemapart(token, schema_uid, pos)
  local del_url = url .. "/api/schemapart/" .. schema_uid .. "/" .. pos.x .. "/" .. pos.y .. "/" .. pos.z .. "/delete"
  return Promise.http(http, del_url, {
    method = "POST",
    data = "delete",
    headers = {
      "Authorization: " .. token
    }
  }):next(function(res)
    if res.code ~= 200 then
      return Promise.rejected("unexpected http code: " .. res.code)
    end
    return true
  end)
end

local function response_handler(res)
  if res.code == 200 then
    return res.json()
  elseif res.code == 404 or res.code == 204 then
    return false
  else
    return Promise.rejected("unexpected http code: " .. res.code)
  end
end


function blockexchange.api.get_schemapart(schema_uid, pos)
  return Promise.http(
    http,
    url .. "/api/schemapart/" .. schema_uid .. "/" .. pos.x .. "/" .. pos.y .. "/" .. pos.z
  ):next(response_handler)
end

function blockexchange.api.get_schemapart_chunk(schema_uid, pos)
  return Promise.http(
    http,
    url .. "/api/schemapart_chunk/" .. schema_uid .. "/" .. pos.x .. "/" .. pos.y .. "/" .. pos.z
  ):next(response_handler)
end

function blockexchange.api.get_first_schemapart(schema_uid)
  return Promise.http(
    http,
    url .. "/api/schemapart_first/" .. schema_uid
  ):next(response_handler)
end

function blockexchange.api.get_next_schemapart(schema_uid, pos)
  return Promise.http(
    http,
    url .. "/api/schemapart_next/" .. schema_uid .. "/" .. pos.x .. "/" .. pos.y .. "/" .. pos.z
  ):next(response_handler)
end

function blockexchange.api.get_next_schemapart_by_mtime(schema_uid, mtime)
  return Promise.http(
    http,
    url .. "/api/schemapart_next/by-mtime/" .. schema_uid .. "/" .. mtime
  ):next(response_handler)
end

function blockexchange.api.count_next_schemapart_by_mtime(schema_uid, mtime)
  return Promise.http(
    http,
    url .. "/api/schemapart_count/by-mtime/" .. schema_uid .. "/" .. mtime
  ):next(function(res)
    if res.code == 200 then
      return res.text()
    elseif res.code == 404 or res.code == 204 then
      return false
    else
      return Promise.rejected("unexpected http code: " .. res.code)
    end
  end):next(function(txt)
    return tonumber(txt)
  end)
end
