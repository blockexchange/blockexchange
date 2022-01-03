
local function shift(ctx)
	ctx.current_pos, ctx.rel_pos, ctx.progress = ctx.iterator()

	-- increment stats
	ctx.current_part = ctx.current_part + 1
	ctx.progress_percent = math.floor(ctx.progress * 100 * 10) / 10
end

local function create_key(schema_id, relative_pos)
	return schema_id .. "/" .. minetest.pos_to_string(relative_pos)
end

-- map of already deleted schemaparts, skip the requests on those
local already_deleted_parts = {}

function blockexchange.save_update_worker(ctx)
	if ctx.cancel then
		ctx.promise:reject("canceled")
	end

	if not ctx.current_pos then
		-- create an array with mod names
		local mod_names = {}
		for k in pairs(ctx.mod_names) do
			table.insert(mod_names, k)
		end

		blockexchange.api.create_schemamods(ctx.token, ctx.schema_id, mod_names):next(function()
			local msg = "[blockexchange] Save-update complete with " .. ctx.total_parts .. " parts"
			minetest.log("action", msg)
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

	local data, node_count, air_only = blockexchange.serialize_part(ctx.current_pos, pos2)

	-- collect mod count info
	blockexchange.collect_node_count(node_count, ctx.mod_names)

	local diff = minetest.get_us_time() - start
	local relative_pos = vector.subtract(ctx.current_pos, ctx.origin)

	if air_only then
		-- delete air-only parts in the remote repository
		minetest.log("action", "[blockexchange] Deleting part " .. minetest.pos_to_string(ctx.current_pos) ..
		" because it is air-only (processing took " .. diff .. " micros)")
		local cache_key = create_key(ctx.schema_id, relative_pos)
		if already_deleted_parts[cache_key] then
			-- this part was already processed a while back, skip it
			minetest.after(blockexchange.min_delay, blockexchange.save_update_worker, ctx)
			return
		end

		blockexchange.api.remove_schemapart(ctx.token, ctx.schema_id, relative_pos):next(function()
			already_deleted_parts[cache_key] = true
			shift(ctx)
			minetest.after(blockexchange.min_delay, blockexchange.save_update_worker, ctx)
		end):catch(function(err_msg)
			ctx.promise:reject(err_msg)
		end)
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
			schema_id = ctx.schema_id,
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
			-- wait a couple seconds
			minetest.after(5, blockexchange.save_update_worker, ctx)
		end)
	end

end
