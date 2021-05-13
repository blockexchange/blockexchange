
-- list of builtin mods
local builtin_mods = {
  air = true
}

local function report_missing_mods(playername, mods)
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

  -- report missing mods
  if #missing_mods > 0 then
    local msg = minetest.colorize("#ff0000", "Missing mods: " .. missing_mods)
    minetest.log("action", msg)
    minetest.chat_send_player(playername, msg)
    end
end

function blockexchange.allocate(playername, pos1, username, schemaname, local_load)
  if local_load then
    -- local operation
    local schema = blockexchange.get_local_schema(schemaname)
    if not schema then
      minetest.chat_send_player(playername, "Schema not found: '" .. schemaname .. "'")
      return
    end
		local pos2 = vector.add(pos1, blockexchange.get_schema_size(schema))
    pos2 = vector.subtract(pos2, 1)

    blockexchange.set_pos(2, playername, pos2)

    local mods = blockexchange.get_local_schemamods(schemaname)
    report_missing_mods(playername, mods)
  else
    -- online
    blockexchange.api.get_schema_by_name(username, schemaname, false):next(function(schema)
      local pos2 = vector.add(pos1, blockexchange.get_schema_size(schema))
      pos2 = vector.subtract(pos2, 1)

      blockexchange.set_pos(2, playername, pos2)

      -- report schema stats
      local msg = "Total parts: " .. schema.total_parts ..
      " total size: " .. schema.total_size .. " bytes"

      minetest.log("action", msg)
      minetest.chat_send_player(playername, msg)

      blockexchange.api.get_schemamods(schema.id):next(function(mods)
        report_missing_mods(playername, mods)
      end):catch(function(http_code)
        local err_msg = "[blockexchange] get schemamods failed with http code: " .. (http_code or "unkown")
        minetest.log("error", err_msg)
        minetest.chat_send_player(playername, minetest.colorize("#ff0000", err_msg))
      end)
    end):catch(function()
      minetest.chat_send_player(playername, "Schema not found: '" ..
        username .. "/" .. schemaname .. "'")
    end)
  end
end
