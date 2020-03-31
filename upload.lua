function blockexchange.upload(pos1, pos2, description, tags)
  blockexchange.create_schema(pos1, pos2, description, tags, function(schema)
    local ctx = {
      schema = schema,
      pos1 = pos1,
      pos2 = pos2,
      totalbytes = 0,
      iterator = blockexchange.iterator(pos1, pos2, blockexchange.part_length),
			node_count = {}
    }

    -- start upload worker with context
    minetest.after(0, blockexchange.upload_worker, ctx)
  end,
	function(http_code)
		minetest.log("error", "Create schema failed with http code: " .. http_code)
	end)
end
