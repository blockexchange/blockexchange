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
