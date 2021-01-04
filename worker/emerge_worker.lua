

blockexchange.register_process_type("emerge", function(ctx, process)
	local hud_taskname = "[" .. ctx._meta.id .. "] Emerging " .. minetest.pos_to_string(ctx.pos1)

  if not ctx.current_pos then
		local msg = "[blockexchange] Emerge complete with " .. ctx.total_parts .. " parts"
    minetest.log("action", msg)
		minetest.chat_send_player(ctx.playername, msg)
    ctx.success = true
		blockexchange.hud_remove(ctx.playername, hud_taskname)
    process.stop()
    return
  end

	blockexchange.hud_update_progress(ctx.playername, hud_taskname, ctx.progress_percent, 0x00FF00)

	local pos2 = vector.add(ctx.current_pos, blockexchange.part_length - 1)
	pos2.x = math.min(pos2.x, ctx.pos2.x)
  pos2.y = math.min(pos2.y, ctx.pos2.y)
  pos2.z = math.min(pos2.z, ctx.pos2.z)

  minetest.emerge_area(ctx.current_pos, pos2, function(_, _, calls_remaining)
    if calls_remaining == 0 then
      -- shift coordinates
      ctx.current_pos = blockexchange.iterator_next(ctx.pos1, ctx.pos2, ctx.current_pos)

      -- increment stats
      ctx.current_part = ctx.current_part + 1
      ctx.progress_percent = math.floor(ctx.current_part / ctx.total_parts * 100 * 10) / 10
    end
  end)

end)
