---------
-- async emerge command


--- emerge the given area
-- @param playername the playername to use in messages
-- @param pos1 lower position to emerge
-- @param pos2 upper position to emerge
-- @return a promise that resolves if the operation is complete
-- @return the job context
function blockexchange.emerge(playername, pos1, pos2)

  local ctx = {
    type = "emerge",
    playername = playername,
    progress_percent = 0
  }

  local promise = Promise.async(function(await)
    local total_parts = 0

    for current_pos, _, progress in blockexchange.iterator(pos1, pos1, pos2) do
      local current_pos2 = vector.add(current_pos, 15)

      ctx.progress_percent = math.floor(progress * 100 * 10) / 10
      blockexchange.log(
        "action",
        "emerging area at " .. minetest.pos_to_string(current_pos) .. " progress: " .. ctx.progress_percent
      )
      await(Promise.emerge_area(current_pos, current_pos2))
      total_parts = total_parts + 1

      if ctx.cancel then
        error("canceled", 0)
      end

      await(Promise.after(blockexchange.min_delay))
    end

    return total_parts
  end)

  return promise, ctx
end

Promise.register_chatcommand("bx_emerge", {
	description = "Emerges the selected region",
  privs = { blockexchange = true },
	func = function(name)
    -- force-enable the hud
    blockexchange.set_player_hud(name, true)

    if blockexchange.get_job_context(name) then
      return true, "There is a job already running"
    end

    local pos1 = blockexchange.get_pos(1, name)
    local pos2 = blockexchange.get_pos(2, name)
    pos1, pos2 = blockexchange.sort_pos(pos1, pos2)

    if not pos1 or not pos2 then
      return false, "you need to set /bx_pos1 and /bx_pos2 first!"
    end

    local promise, ctx = blockexchange.emerge(name, pos1, pos2)
    blockexchange.set_job_context(ctx.playername, ctx)

    promise:always(function()
      blockexchange.set_job_context(ctx.playername, nil)
    end)

    return promise:next(function(total_parts)
      return "emerged " .. total_parts
    end)
  end
})
