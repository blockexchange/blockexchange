local has_monitoring = minetest.get_modpath("monitoring")

local downloaded_blocks

if has_monitoring then
	downloaded_blocks = monitoring.counter(
		"blockexchange_downloaded_blocks", "number of successfully downloaded mapblocks"
	)
end

local function get_hud_taskname(ctx)
	return "[Download] '" .. ctx.playername .. "/" .. ctx.schemaname .. "'"
end

local function finalize(ctx)
	minetest.chat_send_player(ctx.playername, "Download complete with " .. ctx.schema.total_parts .. " parts")
	ctx.success = true
	blockexchange.hud_remove(ctx.playername, get_hud_taskname(ctx))
end

local function place_schemapart(origin, schemapart, ctx)
	if not schemapart then
		finalize(ctx)
		return
	end

	-- increment stats
	ctx.current_part = ctx.current_part + 1
	ctx.progress_percent = math.floor(ctx.current_part / ctx.schema.total_parts * 100 * 10) / 10

	blockexchange.hud_update_progress(ctx.playername, get_hud_taskname(ctx), ctx.progress_percent, 0x00FF00)

	local compressed_metadata = minetest.decode_base64(schemapart.metadata)
	local compressed_data = minetest.decode_base64(schemapart.data)

	local metadata = minetest.parse_json(minetest.decompress(compressed_metadata, "deflate"))
	local data = minetest.decompress(compressed_data, "deflate")

	local pos1 = vector.add(origin, {
		x = schemapart.offset_x,
		y = schemapart.offset_y,
		z = schemapart.offset_z
	})
	local pos2 = vector.add(pos1, vector.subtract(metadata.size, 1))
	local node_names = blockexchange.deserialize_part(pos1, pos2, data, metadata);

	minetest.log("action", "[blockexchange] Download of part " ..
					 minetest.pos_to_string(pos1) ..
					 " completed")

	if node_names["blockexchange:controller"] then
		-- controller found, save schema data to node metadata

		-- find controller positions
		local pos_list = minetest.find_nodes_in_area(pos1, pos2, {"blockexchange:controller"})
		for _, pos in ipairs(pos_list) do
			blockexchange.program_controller(pos, ctx.playername, ctx.schema)
		end
	end

	if has_monitoring then
		downloaded_blocks.inc(1)
	end

	ctx.last_schemapart = schemapart
	minetest.after(blockexchange.min_delay, blockexchange.download_worker, ctx)

	-- TODO: overwrite inworld parts if downloaded part is air-only
end

local function schedule_retry(ctx, http_code)
	local msg = "[blockexchange] download schemapart failed with http code: " ..
		(http_code or "unkown") .. " retrying..."
	minetest.log("error", msg)
	minetest.chat_send_player(ctx.playername, minetest.colorize("#ff0000", msg))
	-- wait a couple seconds
	minetest.after(5, blockexchange.download_worker, ctx)
end


function blockexchange.download_worker(ctx)

	if not ctx.last_schemapart then
		-- get first schemapart
		blockexchange.api.get_first_schemapart(ctx.schema.id, function(schemapart)
			place_schemapart(ctx.pos1, schemapart, ctx)
		end, function(http_code)
			schedule_retry(ctx, http_code)
		end)
	else
		-- next part
		local pos = {
			x = ctx.last_schemapart.offset_x,
			y = ctx.last_schemapart.offset_y,
			z = ctx.last_schemapart.offset_z
		}
		blockexchange.api.get_next_schemapart(ctx.schema.id, pos, function(schemapart)
			place_schemapart(ctx.pos1, schemapart, ctx)
		end, function(http_code)
			schedule_retry(ctx, http_code)
		end)
	end
end
