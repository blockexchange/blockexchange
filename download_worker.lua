
function blockexchange.download_worker(ctx)
	local pos, current_part, total_parts = ctx.iterator()
	if not pos then
    print("Download complete with " .. ctx.totalbytes .. " bytes in " .. total_parts .. " parts")
    return
  end

	local progress_percent = math.floor(current_part / total_parts * 100 * 10) / 10

	minetest.log("Download pos: " .. minetest.pos_to_string(pos) ..
    " Progress: " .. progress_percent .. "% (" .. current_part .. "/" .. total_parts .. ")")

	local relative_pos = vector.subtract(pos, ctx.pos1)

	blockexchange.api.get_schemapart(ctx.schema.id, relative_pos, function(schemapart)
		local start = minetest.get_us_time()

		blockexchange.deserialize_part(pos, schemapart.data);

		local diff = minetest.get_us_time() - start

		local len = #schemapart.data
		ctx.totalbytes = ctx.totalbytes + len

    print("Download of part " .. minetest.pos_to_string(pos) ..
    " completed with " .. len ..
    " bytes (processing took " .. diff .. " micros)")

		minetest.after(0.5, blockexchange.download_worker, ctx)
	end)

end
