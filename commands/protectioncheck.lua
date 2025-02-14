
function blockexchange.protectioncheck(playername, pos1, pos2)

  local ctx = {
    type = "protectioncheck",
    playername = playername,
    current_part = 0,
    progress_percent = 0,
    total_parts = blockexchange.count_schemaparts(pos1, pos2)
  }

  local promise = Promise.async(function(await)
    for current_pos in blockexchange.iterator(pos1, pos1, pos2) do
      local current_pos2 = vector.add(current_pos, 15)
      current_pos2.x = math.min(current_pos2.x, pos2.x)
      current_pos2.y = math.min(current_pos2.y, pos2.y)
      current_pos2.z = math.min(current_pos2.z, pos2.z)

      local protected = blockexchange.is_area_protected(current_pos, current_pos2, playername)

      if not protected then
        -- increment stats
        ctx.current_part = ctx.current_part + 1
        ctx.progress_percent = math.floor(ctx.current_part / ctx.total_parts * 100 * 10) / 10
      else
        return {
          success = false,
          pos1 = current_pos,
          pos2 = current_pos2
        }
      end

      await(Promise.after(blockexchange.min_delay))

      if ctx.cancel then
				error("canceled", 0)
			end
    end

    return {
      success = true,
      total_parts = ctx.total_parts
    }
  end)

  blockexchange.set_job_context(playername, ctx, promise)
  return promise
end
