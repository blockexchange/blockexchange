

function blockexchange.emerge_worker(ctx)

  if not ctx.current_pos then
		local msg = "[blockexchange] Emerge complete with " .. ctx.total_parts .. " parts"
    minetest.log("action", msg)
		minetest.chat_send_player(ctx.playername, msg)
    ctx.success = true
    return
  end

  minetest.log("action", "[blockexchange] Emerge pos: " .. minetest.pos_to_string(ctx.current_pos) ..
    " Progress: " .. ctx.progress_percent .. "% (" .. ctx.current_part .. "/" .. ctx.total_parts .. ")")

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

      -- call again later
      minetest.after(0.5, blockexchange.emerge_worker, ctx)
    end
  end)


end
