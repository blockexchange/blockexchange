local has_monitoring = minetest.get_modpath("monitoring")

local uploaded_blocks

if has_monitoring then
	uploaded_blocks = monitoring.counter(
	"blockexchange_uploaded_blocks",
	"number of successfully uploaded mapblocks"
)
end

local function shift(ctx)
	ctx.current_pos, ctx.rel_pos, ctx.progress = ctx.iterator()

	-- increment stats
	ctx.current_part = ctx.current_part + 1
	ctx.progress_percent = math.floor(ctx.progress * 100 * 10) / 10
end

function blockexchange.save_worker(ctx)
	local hud_taskname = "[Save] '" .. ctx.playername .. "/".. ctx.schemaname .. "'"

	if not ctx.current_pos then
		-- save of individual parts finished, finalize schema and update stats

		-- create an array with mod names
		local mod_names = {}
		for k in pairs(ctx.mod_names) do
			table.insert(mod_names, k)
		end

		if ctx.local_save then
			-- local save
			blockexchange.create_local_schemamods(ctx.schemaname, mod_names)
			local msg = "[blockexchange] Local save complete with " .. ctx.total_parts .. " parts"
			minetest.log("action", msg)
			minetest.chat_send_player(ctx.playername, msg)
			ctx.promise:resolve(ctx.total_parts)
		else
			-- online save
			blockexchange.api.create_schemamods(ctx.token, ctx.schema.id, mod_names):next(function()
				return blockexchange.api.update_schema_stats(ctx.token, ctx.schema.id)
			end):next(function()
				local msg = "[blockexchange] Save complete with " .. ctx.total_parts .. " parts"
				minetest.log("action", msg)
				minetest.chat_send_player(ctx.playername, msg)
				ctx.promise:resolve(ctx.total_parts)
			end):catch(function(http_code)
				local msg = "[blockexchange] finalize schema failed with http code: " .. (http_code or "unkown") ..
				" retry manual on the web-ui please"
				minetest.log("error", msg)
				minetest.chat_send_player(ctx.playername, minetest.colorize("#ff0000", msg))
				ctx.promise:resolve(ctx.total_parts)
			end)
		end

		blockexchange.hud_remove(ctx.playername, hud_taskname)
		return
	end

	blockexchange.hud_update_progress(ctx.playername, hud_taskname, ctx.progress_percent, 0x00FF00)
	local start = minetest.get_us_time()

	local pos2 = vector.add(ctx.current_pos, 15)
	-- clip pos2 to area bounds
	pos2.x = math.min(pos2.x, ctx.pos2.x)
	pos2.y = math.min(pos2.y, ctx.pos2.y)
	pos2.z = math.min(pos2.z, ctx.pos2.z)

	local data, node_count, air_only = blockexchange.serialize_part(ctx.current_pos, pos2)

	-- collect mod count info
	blockexchange.collect_node_count(node_count, ctx.mod_names)

	local diff = minetest.get_us_time() - start
	local relative_pos = vector.subtract(ctx.current_pos, ctx.pos1)

	if node_count["blockexchange:controller"] then
		-- controller found, save upload data to node metadata

		-- find controller positions
		local pos_list = minetest.find_nodes_in_area(ctx.current_pos, pos2, {"blockexchange:controller"})
		for _, pos in ipairs(pos_list) do
			blockexchange.program_controller(pos, ctx.playername, ctx.schema, ctx.origin)
		end
	end

	if air_only then
		-- don't save air-only
		minetest.log("action", "[blockexchange] NOT Saving part " .. minetest.pos_to_string(ctx.current_pos) ..
		" because it is air-only (processing took " .. diff .. " micros)")
		shift(ctx)
		minetest.after(blockexchange.min_delay, blockexchange.save_worker, ctx)
	else
		-- package data properly over the wire
		local metadata = minetest.write_json({
			node_mapping = data.node_mapping,
			size = data.size,
			metadata = data.metadata
		})

		local compressed_metadata = minetest.compress(metadata, "deflate")
		local compressed_data = minetest.compress(data.serialized_data, "deflate")

		local schemapart = {
			schema_id = ctx.schema and ctx.schema.id,
			offset_x = relative_pos.x,
			offset_y = relative_pos.y,
			offset_z = relative_pos.z,
			data = minetest.encode_base64(compressed_data),
			metadata = minetest.encode_base64(compressed_metadata)
		}

		if ctx.local_save then
			-- save locally
			minetest.log("action", "[blockexchange] Saving local schemapart " .. minetest.pos_to_string(relative_pos))
			blockexchange.create_local_schemapart(ctx.schemaname, schemapart)
			shift(ctx)
			minetest.after(blockexchange.min_delay, blockexchange.save_worker, ctx)
		else
			-- upload part online
			blockexchange.api.create_schemapart(ctx.token, schemapart):next(function()
				minetest.log("action", "[blockexchange] Save of part " .. minetest.pos_to_string(ctx.current_pos) ..
				" completed (processing took " .. diff .. " micros)")

				if has_monitoring then
					uploaded_blocks.inc(1)
				end

				shift(ctx)
				minetest.after(blockexchange.min_delay, blockexchange.save_worker, ctx)
			end):catch(function(http_code)
				local msg = "[blockexchange] create schemapart failed with http code: " .. (http_code or "unkown") ..
				" retrying..."
				minetest.log("error", msg)
				minetest.chat_send_player(ctx.playername, minetest.colorize("#ff0000", msg))
				-- wait a couple seconds
				minetest.after(5, blockexchange.save_worker, ctx)
			end)
		end
	end

end
