minetest.register_chatcommand("bx_cleanup", {
	description = "Cleans up the selected region (stray metadata, invalid param2 values)",
  privs = { blockexchange = true },
	func = function(name)
    if blockexchange.get_job_context(name) then
      return true, "There is a job already running"
    end

    local pos1 = blockexchange.get_pos(1, name)
    local pos2 = blockexchange.get_pos(2, name)
    pos1, pos2 = blockexchange.sort_pos(pos1, pos2)

    if not pos1 or not pos2 then
      return false, "you need to set /bx_pos1 and /bx_pos2 first!"
    end

    local promise, ctx = blockexchange.cleanup(name, pos1, pos2)
    blockexchange.set_job_context(ctx.playername, ctx)

    promise:next(function(result)
      blockexchange.set_job_context(ctx.playername, nil)
      local msg = "[blockexchange] Cleanup complete, " ..
        "cleaned metadata: " .. result.meta .. ", cleaned param2: " .. result.param2
      minetest.log("action", msg)
      minetest.chat_send_player(name, msg)
    end):catch(function(err_msg)
      blockexchange.set_job_context(ctx.playername, nil)
      minetest.chat_send_player(name, minetest.colorize("#ff0000", err_msg))
    end)
		return true
  end
})
