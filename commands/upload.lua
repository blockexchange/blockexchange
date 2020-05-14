
function blockexchange.upload(playername, pos1, pos2, name, description)
	pos1, pos2 = blockexchange.sort_pos(pos1, pos2)

	local total_parts =
		math.ceil(math.abs(pos1.x - pos2.x) / blockexchange.part_length) *
		math.ceil(math.abs(pos1.y - pos2.y) / blockexchange.part_length) *
		math.ceil(math.abs(pos1.z - pos2.z) / blockexchange.part_length)

	local token = blockexchange.tokens[playername]
	local license = blockexchange.licenses[playername] or "CC0"

	local ctx = {
		type = "upload",
		playername = playername,
		token = token,
		pos1 = pos1,
		pos2 = pos2,
		current_pos = table.copy(pos1),
		current_part = 0,
		total_parts = total_parts,
		progress_percent = 0,
		mod_count = {}
	}

  blockexchange.api.create_schema(token, pos1, pos2, name, description, license, function(schema)
		ctx.schema = schema
		minetest.log("action", "[blockexchange] schema created with id: " .. schema.id)
		minetest.chat_send_player(playername,
			"[blockexchange] schema created with id: " ..
			minetest.colorize("#00ff00", schema.id)
		)

    -- start upload worker with context
		blockexchange.start_process(ctx)
  end,
	function(http_code)
		local msg = "[blockexchange] create schema failed with http code: " .. (http_code or "unknown")
		minetest.log("error", msg)
		minetest.chat_send_player(playername, minetest.colorize("#ff0000", msg))
		ctx.failed = true
	end)

	return ctx
end
