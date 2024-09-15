
minetest.register_chatcommand("bx_save_local", {
  params = "<name>",
  privs = { blockexchange = true },
  description = "Saves the selected region to the disk",
  func = function(name, schemaname)
    -- force-enable the hud
    blockexchange.set_player_hud(name, true)

    if blockexchange.get_job_context(name) then
      return true, "There is a job already running"
    end

    if not schemaname or schemaname == "" then
      return true, "Usage: /bx_save_local <schemaname>"
    end

    local pos1 = blockexchange.get_pos(1, name)
    local pos2 = blockexchange.get_pos(2, name)

    if not pos1 or not pos2 then
      return true, "you need to set /bx_pos1 and /bx_pos2 first!"
    end

    -- kick off upload with local-save flag
    local promise, ctx = blockexchange.save(name, pos1, pos2, schemaname, true)
    blockexchange.set_job_context(name, ctx)
    promise:next(function(result)
      blockexchange.set_job_context(ctx.playername, nil)
      minetest.chat_send_player(name, "[blockexchange] Local save complete with " .. result.total_parts .. " parts")
    end):catch(function(err_msg)
      minetest.chat_send_player(name, minetest.colorize("#ff0000", err_msg))
      blockexchange.set_job_context(ctx.playername, nil)
    end)

    return true
  end
})

