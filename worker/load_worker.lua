local has_monitoring = minetest.get_modpath("monitoring")

local downloaded_blocks

if has_monitoring then
	downloaded_blocks = monitoring.counter(
		"blockexchange_downloaded_blocks",
		"number of successfully downloaded mapblocks"
	)
end

local function place_schemapart(schemapart, ctx)
	if not schemapart then
		blockexchange.log("action", "Download complete with " .. ctx.total_parts .. " parts")

		-- fetch updated schema and register area for future updates
		blockexchange.register_area(ctx.pos1, ctx.pos2, ctx.playername, ctx.username, ctx.schema)

		ctx.promise:resolve({
			schema = ctx.schema,
			last_schemapart = ctx.last_schemapart
		})
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

local function schedule_retry(ctx, err)
	local msg = "[blockexchange] download schemapart failed: " .. (err or "unkown") .. " retrying..."
	minetest.log("error", msg)

	-- wait a couple seconds
	minetest.after(5, blockexchange.load_worker, ctx)
end


function blockexchange.load_worker(ctx)
	if ctx.cancel then
		ctx.promise:reject("canceled")
		return
	end

	if ctx.from_mtime > 0 then
		-- online, incremental download by mtime
		local mtime = ctx.from_mtime
		if ctx.last_schemapart then
			-- start from last schema part
			mtime = ctx.last_schemapart.mtime
		end
		blockexchange.api.get_next_schemapart_by_mtime(ctx.schema.uid,  mtime):next(function(schemapart)
			place_schemapart(schemapart, ctx, false)
		end):catch(function(err)
			schedule_retry(ctx, err)
		end)
	else
		-- online, full download
		if not ctx.last_schemapart then
			-- start from the beginning
			blockexchange.api.get_first_schemapart(ctx.schema.uid):next(function(schemapart)
				place_schemapart(schemapart, ctx, false)
			end):catch(function(err)
				schedule_retry(ctx, err)
			end)
		else
			-- start from last position
			local pos = {
				x = ctx.last_schemapart.offset_x,
				y = ctx.last_schemapart.offset_y,
				z = ctx.last_schemapart.offset_z
			}
			blockexchange.api.get_next_schemapart(ctx.schema.uid, pos):next(function(schemapart)
				place_schemapart(schemapart, ctx, false)
			end):catch(function(err)
				schedule_retry(ctx, err)
			end)
		end
	end
end
