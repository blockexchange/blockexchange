---------
-- async emerge command

local chunk_length = 80

--- emerge the given area
-- @param playername the playername to use in messages
-- @param pos1 lower position to emerge
-- @param pos2 upper position to emerge
-- @return a promise that resolves if the operation is complete
-- @return the job context
function blockexchange.emerge(playername, pos1, pos2)

  local job = {
    hud_icon = "blockexchange_emerge.png",
    hud_text = "Emerging, starting..."
  }

  job.promise = Promise.async(function(await)
    local chunks = 0

    for current_pos, _, progress in blockexchange.iterator(pos1, pos1, pos2, chunk_length) do
      -- TODO: chunk-granular iterator
      local current_pos2 = vector.add(current_pos, chunk_length)
      local progress_percent = math.floor(progress * 100 * 10) / 10
      job.hud_text = "Emerging, progress: " .. progress_percent .. " %"

      blockexchange.log(
        "action",
        "emerging area at " .. minetest.pos_to_string(current_pos) .. " progress: " .. progress_percent
      )
      await(Promise.emerge_area(current_pos, current_pos2))
      chunks = chunks + 1

      if job.cancel then
        error("canceled", 0)
      end

      await(Promise.after(blockexchange.min_delay))
    end

    return chunks
  end)

  blockexchange.add_job(playername, job)
  return job.promise
end

Promise.register_chatcommand("bx_emerge", {
	description = "Emerges the selected region",
  privs = { blockexchange = true },
	func = function(name)
    local pos1 = blockexchange.get_pos(1, name)
    local pos2 = blockexchange.get_pos(2, name)
    pos1, pos2 = blockexchange.sort_pos(pos1, pos2)

    if not pos1 or not pos2 then
      return false, "you need to set /bx_pos1 and /bx_pos2 first!"
    end

    return blockexchange.emerge(name, pos1, pos2):next(function(chunks)
      return "emerged " .. chunks .. " chunks"
    end)
  end
})
