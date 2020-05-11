

function blockexchange.protectioncheck_worker(ctx)

  if not ctx.current_pos then
		local msg = "[blockexchange] Protection check complete with " .. ctx.total_parts .. " parts"
    minetest.log("action", msg)
		minetest.chat_send_player(ctx.playername, msg)
    ctx.success = true
    return
  end

  minetest.log("action", "[blockexchange] Protection check: " .. minetest.pos_to_string(ctx.current_pos) ..
    " Progress: " .. ctx.progress_percent .. "% (" .. ctx.current_part .. "/" .. ctx.total_parts .. ")")

	local pos2 = vector.add(ctx.current_pos, blockexchange.part_length - 1)
	pos2.x = math.min(pos2.x, ctx.pos2.x)
  pos2.y = math.min(pos2.y, ctx.pos2.y)
  pos2.z = math.min(pos2.z, ctx.pos2.z)

  local protected = blockexchange.is_area_protected(ctx.current_pos, pos2, ctx.playername)

  if not protected then
    -- continue checking
    ctx.current_pos = blockexchange.iterator_next(ctx.pos1, ctx.pos2, ctx.current_pos)

    -- increment stats
    ctx.current_part = ctx.current_part + 1
    ctx.progress_percent = math.floor(ctx.current_part / ctx.total_parts * 100 * 10) / 10

    -- call again later
    minetest.after(0.5, blockexchange.protectioncheck_worker, ctx)
  else
    -- check failed
    print("failed!")
  end



end