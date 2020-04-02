function blockexchange.upload(playername, pos1, pos2, description, tags)
	pos1, pos2 = worldedit.sort_pos(pos1, pos2)
  blockexchange.api.create_schema(pos1, pos2, description, tags, function(schema)
    local ctx = {
			playername = playername,
      schema = schema,
      pos1 = pos1,
      pos2 = pos2,
      iterator = blockexchange.iterator(pos1, pos2, blockexchange.part_length),
			node_count = {}
    }

    -- start upload worker with context
    minetest.after(0, blockexchange.upload_worker, ctx)
  end,
	function(http_code)
		local msg = "[blockexchange] create schema failed with http code: " .. (http_code or "unknown")
		minetest.log("error", msg)
		minetest.chat_send_player(playername, minetest.colorize("#ff0000", msg))
	end)
end
