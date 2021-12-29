
minetest.register_chatcommand("bx_allocate_local", {
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

    blockexchange.allocate(name, pos1, name, schemaname, true):next(function(result)
      minetest.chat_send_player(name, "Total parts: " .. result.schema.total_parts ..
        " total size: " .. result.schema.total_size .. " bytes")

      if #result.missing_mods > 0 then
        minetest.chat_send_player(name, minetest.colorize("#ff0000", "Missing mods: " .. result.missing_mods))
      end

    end):catch(function(err_msg)
      minetest.chat_send_player(name, minetest.colorize("#ff0000", err_msg))
    end)
    return true
  end
})
