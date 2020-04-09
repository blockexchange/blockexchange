
local function shift(ctx)
	ctx.current_pos = blockexchange.iterator_next(ctx.pos1, ctx.pos2, ctx.current_pos)

	-- increment stats
  ctx.current_part = ctx.current_part + 1
  ctx.progress_percent = math.floor(ctx.current_part / ctx.total_parts * 100 * 10) / 10
end

function blockexchange.download_worker(ctx)

	if not ctx.current_pos then
    print("Download complete with " .. ctx.total_parts .. " parts")
		ctx.success = true
    return
  end

	minetest.log("Download pos: " .. minetest.pos_to_string(ctx.current_pos) ..
    " Progress: " .. ctx.progress_percent .. "% (" .. ctx.current_part .. "/" .. ctx.total_parts .. ")")

	local relative_pos = vector.subtract(ctx.current_pos, ctx.pos1)

	blockexchange.api.get_schemapart(ctx.schema.id, relative_pos, function(schemapart)
		local start = minetest.get_us_time()

		blockexchange.deserialize_part(ctx.current_pos, schemapart.data);

		local diff = minetest.get_us_time() - start

    print("Download of part " .. minetest.pos_to_string(ctx.current_pos) ..
    " completed (processing took " .. diff .. " micros)")

		shift(ctx)
		minetest.after(0.5, blockexchange.download_worker, ctx)
	end,
	function(http_code)
		local msg = "[blockexchange] download schemapart failed with http code: " .. (http_code or "unkown")
		minetest.log("error", msg)
		minetest.chat_send_player(ctx.playername, minetest.colorize("#ff0000", msg))
		ctx.failed = true
		-- TODO: retry
	end)

end
