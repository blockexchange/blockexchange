local has_monitoring = minetest.get_modpath("monitoring")

local uploaded_blocks

if has_monitoring then
  uploaded_blocks = monitoring.counter(
    "blockexchange_uploaded_blocks",
    "number of successfully uploaded mapblocks"
  )
end

local function shift(ctx)
  ctx.current_pos = blockexchange.iterator_next(ctx.pos1, ctx.pos2, ctx.current_pos)

  -- increment stats
  ctx.current_part = ctx.current_part + 1
  ctx.progress_percent = math.floor(ctx.current_part / ctx.total_parts * 100 * 10) / 10
end

blockexchange.register_process_type("upload", function(ctx, process)

	local hud_taskname = "[" .. ctx._meta.id .. "] Uploading '" .. ctx.schemaname .. "'"

  if not ctx.current_pos then
		-- upload of individual parts finished, finalize schema and update stats
    -- TODO: move to own process-types/workers
    blockexchange.api.create_schemamods(ctx.token, ctx.schema.id, ctx.mod_count, function()
      blockexchange.api.finalize_schema(ctx.token, ctx.schema.id, function()
        local msg = "[blockexchange] Upload complete with " .. ctx.total_parts .. " parts"
        minetest.log("action", msg)
        minetest.chat_send_player(ctx.playername, msg)
        ctx.success = true
      end,
      function(http_code)
        local msg = "[blockexchange] finalize schema failed with http code: " .. (http_code or "unkown") ..
        " retrying..."
        minetest.log("error", msg)
        minetest.chat_send_player(ctx.playername, minetest.colorize("#ff0000", msg))
      end)
    end,
    function(http_code)
      local msg = "[blockexchange] create schemamod failed with http code: " .. (http_code or "unkown") ..
				" retrying..."
      minetest.log("error", msg)
      minetest.chat_send_player(ctx.playername, minetest.colorize("#ff0000", msg))
    end)

		blockexchange.hud_remove(ctx.playername, hud_taskname)
    process.stop()
    return
  end

	blockexchange.hud_update_progress(ctx.playername, hud_taskname, ctx.progress_percent, 0x00FF00)
  local start = minetest.get_us_time()

	local pos2 = vector.add(ctx.current_pos, blockexchange.part_length - 1)
	pos2.x = math.min(pos2.x, ctx.pos2.x)
  pos2.y = math.min(pos2.y, ctx.pos2.y)
  pos2.z = math.min(pos2.z, ctx.pos2.z)

  local data, node_count, air_only = blockexchange.serialize_part(ctx.current_pos, pos2)

  -- collect mod count info
  for k, v in pairs(node_count) do
    local i = 1
    for str in string.gmatch(k, "([^:]+)") do
      if i == 1 then
        local count = ctx.mod_count[str]
        if not count then
          count = 0
        end
        ctx.mod_count[str] = count + v
      end
      i = i + 1
    end
  end

  local diff = minetest.get_us_time() - start
	local relative_pos = vector.subtract(ctx.current_pos, ctx.pos1)

	if air_only then
		-- don't upload air-only
		shift(ctx)
	else
		-- upload part
	  blockexchange.api.create_schemapart(ctx.token, ctx.schema.id, relative_pos, data, function()
	    minetest.log("action", "[blockexchange] Upload of part " .. minetest.pos_to_string(ctx.current_pos) ..
	    " completed (processing took " .. diff .. " micros)")

	    if has_monitoring then
	      uploaded_blocks.inc(1)
	    end

	    shift(ctx)
	  end,
		function(http_code)
				local msg = "[blockexchange] create schemapart failed with http code: " .. (http_code or "unkown") ..
					" retrying..."
				minetest.log("error", msg)
				minetest.chat_send_player(ctx.playername, minetest.colorize("#ff0000", msg))
	      -- wait a couple seconds
	      process.defer(5)
		end)
	end

end)
