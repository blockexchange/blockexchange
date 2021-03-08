

function blockexchange.protectioncheck_worker(ctx)
	local hud_taskname = "[Protectioncheck] '" .. ctx.playername .. "/".. ctx.schemaname .. "'"

  if not ctx.current_pos then
		local msg = "[blockexchange] Protection check complete with " .. ctx.total_parts .. " parts"
    minetest.log("action", msg)
		minetest.chat_send_player(ctx.playername, msg)

    -- kick off upload
    blockexchange.upload(ctx.playername, ctx.pos1, ctx.pos2, ctx.schemaname)
		blockexchange.hud_remove(ctx.playername, hud_taskname)
    return
  end

	blockexchange.hud_update_progress(ctx.playername, hud_taskname, ctx.progress_percent, 0x00FF00)

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
		minetest.after(0.5, blockexchange.protectioncheck_worker, ctx)
  else
    -- check failed
    minetest.chat_send_player(ctx.playername,
      "[blockexchange] protection check failed between: " ..
      minetest.pos_to_string(ctx.current_pos) .. " and " ..
      minetest.pos_to_string(pos2)
    )
		blockexchange.hud_remove(ctx.playername, hud_taskname)
  end

end
