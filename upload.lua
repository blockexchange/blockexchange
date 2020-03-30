function blockexchange.upload(pos1, pos2)
  blockexchange.create_schema(pos1, pos2, function(schema_id)
    local ctx = {
      schema_id = schema_id,
      pos1 = pos1,
      pos2 = pos2,
      totalbytes = 0,
      iterator = blockexchange.iterator(pos1, pos2, blockexchange.part_length)
    }

    -- start upload worker with context
    minetest.after(0, blockexchange.upload_worker, ctx)
  end)
end
