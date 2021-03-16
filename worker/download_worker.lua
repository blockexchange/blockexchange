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

function blockexchange.download_worker(ctx)
	local hud_taskname = "[Download] '" .. ctx.playername .. "/".. ctx.schemaname .. "'"

	if not ctx.current_pos then
    minetest.chat_send_player(ctx.playername, "Download complete with " .. ctx.total_parts .. " parts")
		ctx.success = true
		blockexchange.hud_remove(ctx.playername, hud_taskname)
    return
  end

	blockexchange.hud_update_progress(ctx.playername, hud_taskname, ctx.progress_percent, 0x00FF00)

	local relative_pos = vector.subtract(ctx.current_pos, ctx.pos1)

	blockexchange.api.get_schemapart(ctx.schema.id, relative_pos, function(schemapart)
		if schemapart then
			-- unpack the data
			local compressed_metadata = minetest.decode_base64(schemapart.metadata)
			local compressed_data = minetest.decode_base64(schemapart.data)

			local metadata = minetest.parse_json(minetest.decompress(compressed_metadata, "deflate"))
			local data = minetest.decompress(compressed_data, "deflate")

			-- only deserialize if the part was found (non-empty)
			local pos2 = vector.add(ctx.current_pos, vector.subtract(metadata.size, 1))
			local node_names = blockexchange.deserialize_part(ctx.current_pos, pos2, data, metadata);

			minetest.log("action", "[blockexchange] Download of part " .. minetest.pos_to_string(ctx.current_pos) ..
	    " completed")

			if node_names["blockexchange:controller"] then
				-- controller found, save schema data to node metadata

				-- find controller positions
				local pos_list = minetest.find_nodes_in_area(ctx.current_pos, pos2, {"blockexchange:controller"})
				for _, pos in ipairs(pos_list) do
					local meta = minetest.get_meta(pos)
					meta:set_string("owner", ctx.playername)
					meta:set_string("username", ctx.username)
					meta:set_string("schemaname", ctx.schemaname)
					meta:set_string("pos1", minetest.pos_to_string(ctx.pos1))
					meta:set_string("pos2", minetest.pos_to_string(ctx.pos2))
					meta:set_string("infotext",
						"Controller for schema '".. ctx.username .. "/" .. ctx.schemaname .. "' " ..
						"owned by '" .. ctx.playername .. "'"
					)
				end
			end

			-- TODO: overwrite inworld parts if downloaded part is air-only
		end

		if has_monitoring then
			-- count 200 and 404 blocks
			downloaded_blocks.inc(1)
		end

		shift(ctx)
		minetest.after(0.5, blockexchange.download_worker, ctx)
	end,
	function(http_code)
		local msg = "[blockexchange] download schemapart failed with http code: " .. (http_code or "unkown") ..
			" retrying..."
		minetest.log("error", msg)
		minetest.chat_send_player(ctx.playername, minetest.colorize("#ff0000", msg))
    -- wait a couple seconds
    minetest.after(5, blockexchange.download_worker, ctx)
	end)

end
