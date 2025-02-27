
function blockexchange.protectioncheck(playername, pos1, pos2)

  local job = {
    hud_icon = "blockexchange_protectioncheck.png",
    hud_text = "Protection-check, starting..."
  }

  local total_parts = 0

  job.promise = Promise.async(function(await)
    for current_pos, _, progress in blockexchange.iterator(pos1, pos1, pos2) do
      local current_pos2 = vector.add(current_pos, 15)
      current_pos2.x = math.min(current_pos2.x, pos2.x)
      current_pos2.y = math.min(current_pos2.y, pos2.y)
      current_pos2.z = math.min(current_pos2.z, pos2.z)

      local protected = blockexchange.is_area_protected(current_pos, current_pos2, playername)

      if not protected then
        -- increment stats
        total_parts = total_parts + 1
        job.hud_text = "Protection-check, progress: " .. math.floor(progress * 100 * 10) / 10 .. " %"
      else
        return {
          success = false,
          pos1 = current_pos,
          pos2 = current_pos2
        }
      end

      await(Promise.after(blockexchange.min_delay))

      if job.cancel then
				error("canceled", 0)
			end
    end

    return {
      success = true,
      total_parts = total_parts
    }
  end)

  blockexchange.add_job(playername, job)
  return job.promise
end
