local has_monitoring = minetest.get_modpath("monitoring")

local downloaded_blocks

if has_monitoring then
	downloaded_blocks = monitoring.counter(
		"blockexchange_downloaded_blocks", "number of successfully downloaded mapblocks"
	)
end

local function get_hud_taskname(ctx)
	return "[Download" .. (ctx.local_load and "-local" or "") .. "] '" .. ctx.playername .. "/" .. ctx.schemaname .. "'"
end

local function finalize(ctx)
	local msg = "Download complete with " .. ctx.schema.total_parts .. " parts"
	minetest.chat_send_player(ctx.playername, msg)
	minetest.log("action", "[blockexchange] " .. msg)
	ctx.promise:resolve(ctx.schema.total_parts)
	blockexchange.hud_remove(ctx.playername, get_hud_taskname(ctx))
end

local function place_schemapart(schemapart, ctx)
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

	local pos1 = vector.add(ctx.origin, {
		x = schemapart.offset_x,
		y = schemapart.offset_y,
		z = schemapart.offset_z
	})
	local pos2 = vector.add(pos1, vector.subtract(metadata.size, 1))
	blockexchange.deserialize_part(pos1, pos2, data, metadata);

	minetest.log("action", "[blockexchange] Download of part " ..
					 minetest.pos_to_string(pos1) ..
					 " completed")

	if has_monitoring then
		downloaded_blocks.inc(1)
	end

	ctx.last_schemapart = schemapart
	minetest.after(blockexchange.min_delay, blockexchange.load_worker, ctx)

	-- TODO: overwrite inworld parts if downloaded part is air-only
end

local function schedule_retry(ctx, http_code)
	local msg = "[blockexchange] download schemapart failed with http code: " ..
		(http_code or "unkown") .. " retrying..."
	minetest.log("error", msg)
	minetest.chat_send_player(ctx.playername, minetest.colorize("#ff0000", msg))
	-- wait a couple seconds
	minetest.after(5, blockexchange.load_worker, ctx)
end


function blockexchange.load_worker(ctx)
	if ctx.local_load then
		-- local operation
		ctx.current_pos = blockexchange.iterator_next(ctx.pos1, ctx.pos2, ctx.current_pos)
		if not ctx.current_pos then
			finalize(ctx)
			return
		end

		local relative_pos = vector.subtract(ctx.current_pos, ctx.pos1)
		minetest.log("action", "[blockexchange] loading local schemapart " .. minetest.pos_to_string(relative_pos))
		local schemapart = blockexchange.get_local_schemapart(
			ctx.schemaname,
			relative_pos.x, relative_pos.y, relative_pos.z
		)
		if schemapart then
			place_schemapart(schemapart, ctx)
		else
			minetest.after(blockexchange.min_delay, blockexchange.load_worker, ctx)
		end

	elseif not ctx.last_schemapart then
		-- online
		-- get first schemapart
		blockexchange.api.get_first_schemapart(ctx.schema.id):next(function(schemapart)
			place_schemapart(schemapart, ctx)
		end):catch(function(http_code)
			schedule_retry(ctx, http_code)
		end)
	else
		-- next part
		local pos = {
			x = ctx.last_schemapart.offset_x,
			y = ctx.last_schemapart.offset_y,
			z = ctx.last_schemapart.offset_z
		}
		blockexchange.api.get_next_schemapart(ctx.schema.id, pos):next(function(schemapart)
			place_schemapart(schemapart, ctx)
		end):catch(function(http_code)
			schedule_retry(ctx, http_code)
		end)
	end
end
