
local function shift(ctx)
	ctx.current_pos, ctx.rel_pos, ctx.progress = ctx.iterator()

	-- increment stats
	ctx.current_part = ctx.current_part + 1
	ctx.progress_percent = math.floor(ctx.progress * 100 * 10) / 10
end

function blockexchange.save_update_worker(ctx)
	local hud_taskname = "[Save-Update] '" .. ctx.playername .. "/".. ctx.schemaname .. "'"

	if not ctx.current_pos then
		blockexchange.hud_remove(ctx.playername, hud_taskname)
		return
	end

	blockexchange.hud_update_progress(ctx.playername, hud_taskname, ctx.progress_percent, 0x00FF00)
	local start = minetest.get_us_time()

	local pos2 = vector.add(ctx.current_pos, 15)
	pos2.x = math.min(pos2.x, ctx.pos2.x)
	pos2.y = math.min(pos2.y, ctx.pos2.y)
	pos2.z = math.min(pos2.z, ctx.pos2.z)

	local data, _, air_only = blockexchange.serialize_part(ctx.current_pos, pos2)

	local diff = minetest.get_us_time() - start
	local relative_pos = vector.subtract(ctx.current_pos, ctx.origin)

	if air_only then
		-- don't save air-only
		minetest.log("action", "[blockexchange] NOT Saving part " .. minetest.pos_to_string(ctx.current_pos) ..
		" because it is air-only (processing took " .. diff .. " micros)")
		shift(ctx)
		minetest.after(blockexchange.min_delay, blockexchange.save_update_worker, ctx)
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

		-- upload part online
		blockexchange.api.create_schemapart(ctx.token, schemapart):next(function()
			minetest.log("action", "[blockexchange] Save-update of part " .. minetest.pos_to_string(ctx.current_pos) ..
			" completed (processing took " .. diff .. " micros)")

			shift(ctx)
			minetest.after(blockexchange.min_delay, blockexchange.save_update_worker, ctx)
		end):catch(function(http_code)
			local msg = "[blockexchange] create schemapart failed with http code: " .. (http_code or "unkown") ..
			" retrying..."
			minetest.log("error", msg)
			minetest.chat_send_player(ctx.playername, minetest.colorize("#ff0000", msg))
			-- wait a couple seconds
			minetest.after(5, blockexchange.save_update_worker, ctx)
		end)
	end

end
