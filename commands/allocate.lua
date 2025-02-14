
-- list of builtin mods
local builtin_mods = {
  air = true
}

local function get_missing_mods(mods)
  -- collect missing mods in a list
  local missing_mods = ""
  for _, modname in ipairs(mods) do
    if not builtin_mods[modname] and not minetest.get_modpath(modname) then
      if #missing_mods > 0 then
        -- add comma separator
        missing_mods = missing_mods .. ","
      end
      missing_mods = missing_mods .. modname
    end
  end

  return missing_mods
end

function blockexchange.allocate(playername, pos1, username, schemaname, local_load)

  return Promise.async(function(await)
    if local_load then
      -- local operation
      local filename = blockexchange.get_local_filename(schemaname)
      local f = io.open(filename, "rb")
      if not f then
        error("file not found: " .. filename, 0)
      end
      local z, err_msg = mtzip.unzip(f)
      if err_msg then
        error("unzip error: " .. err_msg, 0)
      end

      local schema_str
      schema_str, err_msg = z:get("schema.json", true)
      if err_msg then
        error("schema.json error: " .. err_msg, 0)
      end
      local schema = minetest.parse_json(schema_str)
      if not schema then
        error("Schema not found: '" .. schemaname .. "'", 0)
      end
      local pos2 = vector.add(pos1, blockexchange.get_schema_size(schema))
      pos2 = vector.subtract(pos2, 1)

      blockexchange.set_pos(2, playername, pos2)

      local mods_str
      mods_str, err_msg = z:get("mods.json")
      if err_msg then
        error("mods.json error: " .. err_msg, 0)
      end
      f:close()

      local mods = minetest.parse_json(mods_str)
      local missing_mods = get_missing_mods(mods)

      return {
        schema = schema,
        missing_mods = missing_mods
      }
    else
      -- online
      local schema, err = await(blockexchange.api.get_schema_by_name(username, schemaname, false))
      if err then
        error("fetch schema error: " .. err, 0)
      elseif not schema then
        error("Schema not found: '" .. username .. "/" .. schemaname .. "'", 0)
      end

      local pos2 = vector.add(pos1, blockexchange.get_schema_size(schema))
      pos2 = vector.subtract(pos2, 1)
      blockexchange.set_pos(2, playername, pos2)

      local mods
      mods, err = await(blockexchange.api.get_schemamods(schema.uid))
      if err then
        error("fetch mods error: " .. err, 0)
      end

      local missing_mods = get_missing_mods(mods)
      return {
        schema = schema,
        missing_mods = missing_mods
      }
    end
  end)
end

local function allocate_reporter(result)
  local msg = "Total parts: " .. result.schema.total_parts ..
    " total size: " .. result.schema.total_size .. " bytes"

  if #result.missing_mods > 0 then
    msg = msg .. ", "
    msg = msg .. minetest.colorize("#ff0000", "missing mods: " .. result.missing_mods)
  end

  return msg
end

Promise.register_chatcommand("bx_allocate_local", {
  params = "<schemaname>",
  description = "Show where the selected schema would end up",
  privs = { blockexchange = true },
  func = function(name, schemaname)
    local pos1 = blockexchange.get_pos(1, name)

    if not pos1 then
      return false, "you need to set /bx_pos1 first!"
    end

    if not schemaname or schemaname == "" then
      return false, "Usage: /bx_allocate_local <schemaname>"
    end

    return blockexchange.allocate(name, pos1, name, schemaname, true):next(allocate_reporter)
  end
})

if blockexchange.is_online then
  Promise.register_chatcommand("bx_allocate", {
    params = "<username> <schemaname>",
    description = "Show where the selected schema would end up",
    privs = { blockexchange = true },
    func = function(name, param)
      local pos1 = blockexchange.get_pos(1, name)

      if not pos1 then
        return false, "you need to set /bx_pos1 first!"
      end

      local _, _, username, schemaname = string.find(param, "^([^%s]+)%s+(.*)$")
      if not username or not schemaname then
        return false, "Usage: /bx_allocate <username> <schemaname>"
      end

      return blockexchange.allocate(name, pos1, username, schemaname):next(allocate_reporter)
    end
  })
end
