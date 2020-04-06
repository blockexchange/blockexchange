
local function shift(ctx)
  ctx.current_pos = blockexchange.iterator_next(ctx.pos1, ctx.pos2, ctx.current_pos)

  -- increment stats
  ctx.current_part = ctx.current_part + 1
  ctx.progress_percent = math.floor(ctx.current_part / ctx.total_parts * 100 * 10) / 10
end

function blockexchange.upload_worker(ctx)

  if not ctx.current_pos then
    blockexchange.api.create_schemamods(ctx.token, ctx.schema.uid, ctx.mod_count, function()
      blockexchange.api.finalize_schema(ctx.token, ctx.schema.uid, function()
        minetest.log("action", "[blockexchange] Upload complete with " .. ctx.total_parts .. " parts")
        ctx.success = true
      end)
    end,
    function(http_code)
      local msg = "[blockexchange] create schemamod failed with http code: " .. (http_code or "unkown")
      minetest.log("error", msg)
      minetest.chat_send_player(ctx.playername, minetest.colorize("#ff0000", msg))
    end)

    return
  end

  minetest.log("action", "[blockexchange] Upload pos: " .. minetest.pos_to_string(ctx.current_pos) ..
    " Progress: " .. ctx.progress_percent .. "% (" .. ctx.current_part .. "/" .. ctx.total_parts .. ")")
  local start = minetest.get_us_time()

	local pos2 = vector.add(ctx.current_pos, blockexchange.part_length - 1)
	pos2.x = math.min(pos2.x, ctx.pos2.x)
  pos2.y = math.min(pos2.y, ctx.pos2.y)
  pos2.z = math.min(pos2.z, ctx.pos2.z)

  local data, node_count = blockexchange.serialize_part(ctx.current_pos, pos2)

  -- collect mod count info
  for k, v in pairs(node_count) do
    local i = 1
    for str in string.gmatch(k, "([^:]+)") do
      if i == 1 then
        local count = ctx.mod_count[str]
        if not count then
          count = 0
        end
        ctx.mod_count[str] = count + v
      end
      i = i + 1
    end
  end

  local diff = minetest.get_us_time() - start

	local relative_pos = vector.subtract(ctx.current_pos, ctx.pos1)

	--[[
	local json = minetest.write_json(data, true);
	local file = io.open(minetest.get_worldpath().."/schemapart_" .. ctx.schema.id .. "_" ..
		minetest.pos_to_string(relative_pos) .. ".json", "w" );
	if file then
		file:write(json)
		file:close()
	end
	--]]

  blockexchange.api.create_schemapart(ctx.token, ctx.schema.uid, relative_pos, data, function()
    minetest.log("action", "[blockexchange] Upload of part " .. minetest.pos_to_string(ctx.current_pos) ..
    " completed (processing took " .. diff .. " micros)")

    shift(ctx)

		minetest.after(0.5, blockexchange.upload_worker, ctx)
  end,
	function(http_code)
			local msg = "[blockexchange] create schemapart failed with http code: " .. (http_code or "unkown")
			minetest.log("error", msg)
			minetest.chat_send_player(ctx.playername, minetest.colorize("#ff0000", msg))
      ctx.failed = true
      -- TODO: retry
	end)

end
