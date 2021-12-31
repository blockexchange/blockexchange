

function blockexchange.protectioncheck_worker(ctx)
	if ctx.cancel then
		ctx.promise:reject("canceled")
	end

  if not ctx.current_pos then
		local msg = "[blockexchange] Protection check complete with " .. ctx.total_parts .. " parts"
    minetest.log("action", msg)

		-- mark as successful (for test)
		ctx.success = true
    ctx.promise:resolve({
      success = true,
      total_parts = ctx.total_parts
    })
    return
  end

	local pos2 = vector.add(ctx.current_pos, 15)
	pos2.x = math.min(pos2.x, ctx.pos2.x)
  pos2.y = math.min(pos2.y, ctx.pos2.y)
  pos2.z = math.min(pos2.z, ctx.pos2.z)

  local protected = blockexchange.is_area_protected(ctx.current_pos, pos2, ctx.playername)

  if not protected then
    -- continue checking
    ctx.current_pos, ctx.rel_pos, ctx.progress = ctx.iterator()

    -- increment stats
    ctx.current_part = ctx.current_part + 1
    ctx.progress_percent = math.floor(ctx.progress * 100 * 10) / 10
		minetest.after(blockexchange.min_delay, blockexchange.protectioncheck_worker, ctx)
  else
    -- check failed
    ctx.promise:resolve({
      success = false,
      pos1 = ctx.current_pos,
      pos2 = pos2
    })
  end

end
