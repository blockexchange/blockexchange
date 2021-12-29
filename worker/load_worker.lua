local has_monitoring = minetest.get_modpath("monitoring")

local downloaded_blocks

if has_monitoring then
	downloaded_blocks = monitoring.counter(
		"blockexchange_downloaded_blocks", "number of successfully downloaded mapblocks"
	)
end

local function finalize(ctx)
	local msg = "Download complete with " .. ctx.schema.total_parts .. " parts"
	minetest.log("action", "[blockexchange] " .. msg)
	ctx.promise:resolve({
		schema = ctx.schema
	})
end

local function place_schemapart(schemapart, ctx)
	if not schemapart then
		finalize(ctx)
		return
	end

	-- increment stats
	ctx.current_part = ctx.current_part + 1
	ctx.progress_percent = math.floor(ctx.current_part / ctx.schema.total_parts * 100 * 10) / 10

	local pos1, pos2, _, metadata = blockexchange.place_schemapart(schemapart, ctx.origin)

	minetest.log("action", "[blockexchange] Download of part " ..
					 minetest.pos_to_string(pos1) ..
					 " completed")

	if metadata.node_mapping["blockexchange:controller"] and not ctx.controller_placed then
		-- controller found, save schema data to node metadata

		-- find controller positions
		local pos_list = minetest.find_nodes_in_area(pos1, pos2, {"blockexchange:controller"})
		if #pos_list >= 1 then
			blockexchange.program_controller(pos_list[1], ctx.playername, ctx.schema, ctx.origin)
			-- there can only be one
			ctx.controller_placed = true
		end
	end

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

	-- wait a couple seconds
	minetest.after(5, blockexchange.load_worker, ctx)
end


function blockexchange.load_worker(ctx)
	if ctx.local_load then
		-- local operation
		local current_pos = ctx.iterator()

		if not current_pos then
			finalize(ctx)
			return
		end

		local relative_pos = vector.subtract(current_pos, ctx.pos1)
		local schemapart = blockexchange.get_local_schemapart(
			ctx.schemaname,
			relative_pos.x, relative_pos.y, relative_pos.z
		)
		if schemapart then
			place_schemapart(schemapart, ctx, false)
		else
			minetest.after(blockexchange.min_delay, blockexchange.load_worker, ctx)
		end

	elseif not ctx.last_schemapart then
		-- online
		-- get first schemapart
		blockexchange.api.get_first_schemapart(ctx.schema.id):next(function(schemapart)
			place_schemapart(schemapart, ctx, false)
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
			place_schemapart(schemapart, ctx, false)
		end):catch(function(http_code)
			schedule_retry(ctx, http_code)
		end)
	end
end
