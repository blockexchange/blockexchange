

function blockexchange.emerge_worker(ctx)
	local hud_taskname = "[Emerge] '" .. minetest.pos_to_string(ctx.pos1) ..
		" - " .. minetest.pos_to_string(ctx.pos2) .. "'"

  if not ctx.current_pos then
    ctx.promise:resolve(ctx.total_parts)
		blockexchange.hud_remove(ctx.playername, hud_taskname)
    return
  end

	blockexchange.hud_update_progress(ctx.playername, hud_taskname, ctx.progress_percent, 0x00FF00)

	local pos2 = vector.add(ctx.current_pos, 15)
	pos2.x = math.min(pos2.x, ctx.pos2.x)
  pos2.y = math.min(pos2.y, ctx.pos2.y)
  pos2.z = math.min(pos2.z, ctx.pos2.z)

  minetest.emerge_area(ctx.current_pos, pos2, function(_, _, calls_remaining)
    if calls_remaining == 0 then
      -- shift coordinates
      ctx.current_pos, ctx.rel_pos, ctx.progress = ctx.iterator()

      -- increment stats
      ctx.current_part = ctx.current_part + 1
      ctx.progress_percent = math.floor(ctx.progress * 100 * 10) / 10
			minetest.after(0.1, blockexchange.emerge_worker, ctx)
    end
  end)

end
