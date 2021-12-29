minetest.register_chatcommand("bx_emerge", {
	description = "Emerges the selected region",
  privs = { blockexchange = true },
	func = function(name)
    if blockexchange.get_job_context(name) then
      return true, "There is a job already running"
    end

    local pos1 = blockexchange.get_pos(1, name)
    local pos2 = blockexchange.get_pos(2, name)

    if not pos1 or not pos2 then
      return false, "you need to set /bx_pos1 and /bx_pos2 first!"
    end

    local promise, ctx = blockexchange.emerge(name, pos1, pos2)
    blockexchange.set_job_context(ctx.playername, ctx)

    promise:next(function(total_parts)
      blockexchange.set_job_context(ctx.playername, nil)
      local msg = "[blockexchange] Emerge complete with " .. total_parts .. " parts"
      minetest.log("action", msg)
      minetest.chat_send_player(name, msg)
    end)
		return true
  end
})
