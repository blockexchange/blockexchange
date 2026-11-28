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

--- patches an existing remote schemapart, only the nodes selected by the patchfilter are replaced
-- @param token the token in string format
-- @param schemapart the schemapart with the new node data (same size as the remote part)
-- @param patchfilter a string with one byte per node (0x01 nodename, 0x02 param1, 0x04 param2, 0x08 metadata)
-- @return a promise with the patched remote schemapart, nil if the remote part does not exist
function blockexchange.api.patch_schemapart(token, schemapart, patchfilter)
  return Promise.json(http, url .. "/api/schemapart/patch", {
    method = "POST",
    data = {
      schema_uid = schemapart.schema_uid,
      offset_x = schemapart.offset_x,
      offset_y = schemapart.offset_y,
      offset_z = schemapart.offset_z,
      data = schemapart.data,
      metadata = schemapart.metadata,
      patchfilter = core.encode_base64(patchfilter)
    },
    headers = {
      "Authorization: " .. token
    }
  })
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

--- returns all schemaparts of a chunk (5x5x5 parts, see blockexchange.chunk_size)
-- needs api version 1.2 (see blockexchange.api.supports_chunks)
-- @param schema_uid the uid of the schema
-- @param pos the offset of the chunk relative to the schema origin, has to be a multiple of blockexchange.chunk_size
-- @return a promise resolving with a list of schemaparts, false (or an empty list) if the chunk is empty
function blockexchange.api.get_schemapart_chunk(schema_uid, pos)
  return Promise.http(
    http,
    url .. "/api/schemapart_chunk/" .. schema_uid .. "/" .. pos.x .. "/" .. pos.y .. "/" .. pos.z,
    -- up to 125 parts per response
    { timeout = 30 }
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
