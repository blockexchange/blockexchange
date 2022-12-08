local has_monitoring = minetest.get_modpath("monitoring")

local downloaded_blocks

if has_monitoring then
	downloaded_blocks = monitoring.counter(
		"blockexchange_downloaded_blocks",
		"number of successfully downloaded mapblocks"
	)
end

local function finalize(ctx)
	local msg = "Download complete with " .. ctx.total_parts .. " parts"
	minetest.log("action", "[blockexchange] " .. msg)
	if not ctx.local_load then
		-- fetch updated schema and register area for future updates
		blockexchange.register_area(ctx.pos1, ctx.pos2, ctx.username, ctx.schema)
	end

	ctx.promise:resolve({
		schema = ctx.schema,
		last_schemapart = ctx.last_schemapart
	})
end

local function place_schemapart(schemapart, ctx)
	if not schemapart then
		finalize(ctx)
		return
	end

	-- increment stats
	ctx.current_part = ctx.current_part + 1
	ctx.progress_percent = math.floor(ctx.current_part / ctx.total_parts * 100 * 10) / 10

	local pos1 = blockexchange.place_schemapart(schemapart, ctx.origin)
	minetest.log("action", "[blockexchange] Download of part " .. minetest.pos_to_string(pos1) .. " completed")

	if has_monitoring then
		downloaded_blocks.inc(1)
	end

	ctx.last_schemapart = schemapart
	minetest.after(blockexchange.min_delay, blockexchange.load_worker, ctx)

	-- TODO: overwrite inworld parts if downloaded part is air-only
end

local function schedule_retry(ctx, http_code)
	local msg = "[blockexchange] download schemapart failed with http code: " .. (http_code or "unkown") .. " retrying..."
	minetest.log("error", msg)

	-- wait a couple seconds
	minetest.after(5, blockexchange.load_worker, ctx)
end


function blockexchange.load_worker(ctx)
	if ctx.cancel then
		ctx.promise:reject("canceled")
		return
	end

	if ctx.local_load then
		-- local operation
		local current_pos = ctx.iterator()

		if not current_pos then
			finalize(ctx)
			return
		end

		local relative_pos = vector.subtract(current_pos, ctx.pos1)
		local filename = "schemapart_" .. relative_pos.x .. "_" .. relative_pos.y .. "_" .. relative_pos.z .. ".json"
		local entry = ctx.zip:get_entry(filename)
		if entry then
			-- non-air part
			local schemapart_str, err_msg = ctx.zip:get(filename, true)
			if err_msg then
				ctx.promise:reject("schemapart error: " .. err_msg)
				return
			end
			local schemapart = minetest.parse_json(schemapart_str)
			place_schemapart(schemapart, ctx, false)
		else
			minetest.after(blockexchange.min_delay, blockexchange.load_worker, ctx)
		end

	elseif ctx.from_mtime > 0 then
		-- online, incremental download by mtime
		local mtime = ctx.from_mtime
		if ctx.last_schemapart then
			-- start from last schema part
			mtime = ctx.last_schemapart.mtime
		end
		blockexchange.api.get_next_schemapart_by_mtime(ctx.schema.id,  mtime):next(function(schemapart)
			place_schemapart(schemapart, ctx, false)
		end):catch(function(http_code)
			schedule_retry(ctx, http_code)
		end)
	else
		-- online, full download
		if not ctx.last_schemapart then
			-- start from the beginning
			blockexchange.api.get_first_schemapart(ctx.schema.id):next(function(schemapart)
				place_schemapart(schemapart, ctx, false)
			end):catch(function(http_code)
				schedule_retry(ctx, http_code)
			end)
		else
			-- start from last position
			local pos = {
				x = ctx.last_schemapart.offset_x,
				y = ctx.last_schemapart.offset_y,
				z = ctx.last_schemapart.offset_z
			}
			blockexchange.api.get_next_schemapart(ctx.schema.id, pos):next(function(schemapart)
				place_schemapart(schemapart, ctx, false)
			end):catch(function(http_code)
				schedule_retry(ctx, http_code)
			end)
		end
	end
end
