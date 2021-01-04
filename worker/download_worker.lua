local has_monitoring = minetest.get_modpath("monitoring")

local downloaded_blocks

if has_monitoring then
  downloaded_blocks = monitoring.counter(
    "blockexchange_downloaded_blocks",
    "number of successfully downloaded mapblocks"
  )
end

local function shift(ctx)
	ctx.current_pos = blockexchange.iterator_next(ctx.pos1, ctx.pos2, ctx.current_pos)

	-- increment stats
  ctx.current_part = ctx.current_part + 1
  ctx.progress_percent = math.floor(ctx.current_part / ctx.total_parts * 100 * 10) / 10
end

blockexchange.register_process_type("download", function(ctx, process)

	local hud_taskname = "[" .. ctx._meta.id .. "] Downloading '" .. ctx.schemaname .. "'"

	if not ctx.current_pos then
    minetest.chat_send_player(ctx.playername, "Download complete with " .. ctx.total_parts .. " parts")
		ctx.success = true
		blockexchange.hud_remove(ctx.playername, hud_taskname)
		process.stop()
    return
  end

	blockexchange.hud_update_progress(ctx.playername, hud_taskname, ctx.progress_percent, 0x00FF00)

	local relative_pos = vector.subtract(ctx.current_pos, ctx.pos1)

	blockexchange.api.get_schemapart(ctx.schema.id, relative_pos, function(schemapart)
		if schemapart then
			-- only deserialize if the part was found (non-empty)
			blockexchange.deserialize_part(ctx.current_pos, schemapart.data);

			minetest.log("action", "[blockexchange] Download of part " .. minetest.pos_to_string(ctx.current_pos) ..
	    " completed")

			-- TODO: overwrite inworld parts if downloaded part is air-only
		end

		if has_monitoring then
			-- count 200 and 404 blocks
			downloaded_blocks.inc(1)
		end

		shift(ctx)
	end,
	function(http_code)
		local msg = "[blockexchange] download schemapart failed with http code: " .. (http_code or "unkown") ..
			" retrying..."
		minetest.log("error", msg)
		minetest.chat_send_player(ctx.playername, minetest.colorize("#ff0000", msg))
    -- wait a couple seconds
    process.defer(5)
	end)

end)
