
function blockexchange.upload_worker(ctx)
  local pos, current_part, total_parts = ctx.iterator()
  if not pos then
    blockexchange.finalize_schema(ctx.schema.id, function()
      print("Upload complete with " .. ctx.totalbytes .. " bytes in " .. total_parts .. " parts")
    end)
    return
  end

  local progress_percent = math.floor(current_part / total_parts * 100 * 10) / 10

  minetest.log("Upload pos: " .. minetest.pos_to_string(pos) ..
    " Progress: " .. progress_percent .. "% (" .. current_part .. "/" .. total_parts .. ")")
  local start = minetest.get_us_time()

  local data = blockexchange.serialize_part(pos, ctx.pos2)
  ctx.totalbytes = ctx.totalbytes + #data

  local diff = minetest.get_us_time() - start

	local relative_pos = vector.subtract(pos, ctx.pos1)

  blockexchange.create_schemapart(ctx.schema.id, relative_pos, data, function()
    print("Upload of part " .. minetest.pos_to_string(pos) ..
    " completed with " .. #data ..
    " bytes (processing took " .. diff .. " micros)")
  end)

  minetest.after(0.5, blockexchange.upload_worker, ctx)
end
