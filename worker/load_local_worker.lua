
function blockexchange.load_local_worker(ctx)
	return Promise.async(function(await)
		for current_pos in blockexchange.iterator(ctx.origin, ctx.pos1, ctx.pos2) do
			local relative_pos = vector.subtract(current_pos, ctx.pos1)
			local filename = "schemapart_" .. relative_pos.x .. "_" .. relative_pos.y .. "_" .. relative_pos.z .. ".json"
			local entry = ctx.zip:get_entry(filename)
			if entry then
				-- non-air part
				local schemapart_str, err_msg = ctx.zip:get(filename, true)
				if err_msg then
					error("schemapart error: " .. err_msg, 0)
				end
				local schemapart = minetest.parse_json(schemapart_str)

				-- increment stats
				ctx.current_part = ctx.current_part + 1
				ctx.progress_percent = math.floor(ctx.current_part / ctx.total_parts * 100 * 10) / 10

				local pos1 = blockexchange.place_schemapart(schemapart, ctx.origin)
				minetest.log("action", "[blockexchange] Extraction of part " .. minetest.pos_to_string(pos1) .. " completed")

				ctx.last_schemapart = schemapart
			end

			if ctx.cancel then
				error("canceled", 0)
			end
			await(Promise.after(blockexchange.min_delay))
		end

		local msg = "Local extraction complete with " .. ctx.total_parts .. " parts"
		minetest.log("action", "[blockexchange] " .. msg)
	end)

end
