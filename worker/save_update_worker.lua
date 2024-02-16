
local function shift(ctx)
	ctx.current_pos, ctx.rel_pos, ctx.progress = ctx.iterator()

	-- increment stats
	ctx.current_part = ctx.current_part + 1
	ctx.progress_percent = math.floor(ctx.progress * 100 * 10) / 10
end

function blockexchange.save_update_worker(ctx)
	if ctx.cancel then
		ctx.promise:reject("canceled")
		return
	end

	if not ctx.token then
		ctx.promise:reject("no token found")
		return
	end

	if not ctx.current_pos then
		-- create an array with mod names
		local mod_names = {}
		for k in pairs(ctx.mod_names) do
			table.insert(mod_names, k)
		end

		blockexchange.api.create_schemamods(ctx.token, ctx.schema_uid, mod_names):next(function()
			local msg = "[blockexchange] Save-update complete with " .. ctx.total_parts .. " parts"
			minetest.log("action", msg)
			-- update screenshot
			return blockexchange.api.update_screenshot(ctx.token, ctx.schema_uid)
		end):next(function()
			ctx.promise:resolve(ctx.total_parts)
		end):catch(function(http_code)
			local msg = "[blockexchange] mod-update failed with http code: " .. (http_code or "unkown")
			minetest.log("error", msg)
			ctx.promise:reject(msg)
		end)
		return
	end

	local start = minetest.get_us_time()

	local pos2 = vector.add(ctx.current_pos, 15)
	pos2.x = math.min(pos2.x, ctx.pos2.x)
	pos2.y = math.min(pos2.y, ctx.pos2.y)
	pos2.z = math.min(pos2.z, ctx.pos2.z)

	local data, node_count = blockexchange.serialize_part(ctx.current_pos, pos2)

	-- collect mod count info
	blockexchange.collect_node_count(node_count, ctx.mod_names)

	local diff = minetest.get_us_time() - start
	local relative_pos = vector.subtract(ctx.current_pos, ctx.origin)

	-- package data properly over the wire
	local schemapart = {
		schema_uid = ctx.schema_uid,
		offset_x = relative_pos.x,
		offset_y = relative_pos.y,
		offset_z = relative_pos.z,
		data = minetest.encode_base64(blockexchange.compress_data(data)),
		metadata = minetest.encode_base64(blockexchange.compress_metadata(data))
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
		-- wait a couple seconds
		minetest.after(5, blockexchange.save_update_worker, ctx)
	end)
end
