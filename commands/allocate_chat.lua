
minetest.register_chatcommand("bx_allocate", {
  params = "<username> <schemaname>",
  description = "Show where the selected schema would end up",
  privs = { blockexchange = true },
  func = blockexchange.api_check_wrapper(function(name, param)
    local pos1 = blockexchange.get_pos(1, name)

    if not pos1 then
      return false, "you need to set /bx_pos1 first!"
    end

    local _, _, username, schemaname = string.find(param, "^([^%s]+)%s+(.*)$")
    if not username or not schemaname then
      return false, "Usage: /bx_allocate <username> <schemaname>"
    end

    blockexchange.allocate(name, pos1, username, schemaname):next(function(result)
      minetest.chat_send_player(name, "Total parts: " .. result.schema.total_parts ..
        " total size: " .. result.schema.total_size .. " bytes")

      if #result.missing_mods > 0 then
        minetest.chat_send_player(name, minetest.colorize("#ff0000", "Missing mods: " .. result.missing_mods))
      end
    end):catch(function(err_msg)
      minetest.chat_send_player(name, minetest.colorize("#ff0000", err_msg))
    end)
    return true
  end)
})
