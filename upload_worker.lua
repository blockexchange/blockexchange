
function blockexchange.upload_worker(ctx)
  local pos, current_part, total_parts = ctx.iterator()
  if not pos then
    blockexchange.api.finalize_schema(ctx.schema.id, ctx.node_count, function()
      print("Upload complete with " .. total_parts .. " parts")
    end)
    return
  end

  local progress_percent = math.floor(current_part / total_parts * 100 * 10) / 10

  minetest.log("Upload pos: " .. minetest.pos_to_string(pos) ..
    " Progress: " .. progress_percent .. "% (" .. current_part .. "/" .. total_parts .. ")")
  local start = minetest.get_us_time()

	local pos2 = vector.add(pos, blockexchange.part_length)
	pos2.x = math.min(pos2.x, ctx.pos2.x)
  pos2.y = math.min(pos2.y, ctx.pos2.y)
  pos2.z = math.min(pos2.z, ctx.pos2.z)

  local data = blockexchange.serialize_part(pos, pos2, ctx.node_count)

  local diff = minetest.get_us_time() - start

	local relative_pos = vector.subtract(pos, ctx.pos1)

  blockexchange.api.create_schemapart(ctx.schema.id, relative_pos, data, function()
    print("Upload of part " .. minetest.pos_to_string(pos) ..
    " completed with " .. #data ..
    " bytes (processing took " .. diff .. " micros)")

		minetest.after(0.5, blockexchange.upload_worker, ctx)
	  end,
		function(http_code)
			local msg = "[blockexchange] create schemapart failed with http code: " .. (http_code or "unkown")
			minetest.log("error", msg)
			minetest.chat_send_player(ctx.playername, minetest.colorize("#ff0000", msg))
	end)

end
