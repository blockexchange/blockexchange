---------
-- async cleanup command

--- cleanup the given area
-- @param playername the playername to update progress in
-- @param pos1 lower position to emerge
-- @param pos2 upper position to emerge
-- @return a promise that resolves if the operation is complete
function blockexchange.cleanup(playername, pos1, pos2)
  local result = {
    meta = 0,
    param2 = 0
  }

  local job = {
    hud_icon = "blockexchange_cleanup.png",
    hud_text = "Cleanup, starting..."
  }

  job.promise = Promise.async(function(await)
    for current_pos, _, progress in blockexchange.iterator(pos1, pos1, pos2) do
      local current_pos2 = vector.add(current_pos, 15)
      current_pos2.x = math.min(current_pos2.x, pos2.x)
      current_pos2.y = math.min(current_pos2.y, pos2.y)
      current_pos2.z = math.min(current_pos2.z, pos2.z)

      local area_result = blockexchange.cleanup_area(current_pos, current_pos2)
      result.meta = result.meta + area_result.meta
      result.param2 = result.param2 + area_result.param2

      job.hud_text = "Cleanup, progress: " .. math.floor(progress * 100 * 10) / 10 .. " %"

      await(Promise.after(blockexchange.min_delay))

      if job.cancel then
        error("canceled", 0)
      end
    end

    return result
  end)

  blockexchange.add_job(playername, job)
  return job.promise
end

Promise.register_chatcommand("bx_cleanup", {
  description = "Cleans up the selected region (stray metadata, invalid param2 values)",
  privs = { blockexchange = true },
  func = function(name)
    local pos1 = blockexchange.get_pos(1, name)
    local pos2 = blockexchange.get_pos(2, name)
    pos1, pos2 = blockexchange.sort_pos(pos1, pos2)

    if not pos1 or not pos2 then
      return false, "you need to set /bx_pos1 and /bx_pos2 first!"
    end

    return blockexchange.cleanup(name, pos1, pos2):next(function(result)
      return "cleaned metadata: " .. result.meta .. ", cleaned param2: " .. result.param2
    end)
  end
})
