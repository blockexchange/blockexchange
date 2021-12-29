
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
  local promise = Promise.new()

  if local_load then
    -- local operation
    local schema = blockexchange.get_local_schema(schemaname)
    if not schema then
      promise:reject("Schema not found: '" .. schemaname .. "'")
      return
    end
		local pos2 = vector.add(pos1, blockexchange.get_schema_size(schema))
    pos2 = vector.subtract(pos2, 1)

    blockexchange.set_pos(2, playername, pos2)

    local mods = blockexchange.get_local_schemamods(schemaname)
    local missing_mods = get_missing_mods(playername, mods)

    promise:resolve({
      schema = schema,
      missing_mods = missing_mods
    })
  else
    -- online
    blockexchange.api.get_schema_by_name(username, schemaname, false):next(function(schema)
      local pos2 = vector.add(pos1, blockexchange.get_schema_size(schema))
      pos2 = vector.subtract(pos2, 1)
      blockexchange.set_pos(2, playername, pos2)

      blockexchange.api.get_schemamods(schema.id):next(function(mods)
        local missing_mods = get_missing_mods(mods)
        promise:resolve({
          schema = schema,
          missing_mods = missing_mods
        })
      end):catch(function(http_code)
        local err_msg = "[blockexchange] get schemamods failed with http code: " .. (http_code or "unkown")
        minetest.log("error", err_msg)
        promise:reject(err_msg)
      end)
    end):catch(function()
      promise:reject("Schema not found: '" .. username .. "/" .. schemaname .. "'")
    end)
  end

  return promise
end
