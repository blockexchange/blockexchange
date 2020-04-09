
function blockexchange.allocate(playername, pos1, username, schemaname)
  blockexchange.api.get_schema_by_name(username, schemaname, function(schema)
    local pos2 = vector.add(pos1, {x=schema.size_x, y=schema.size_y, z=schema.size_z})
    pos2 = vector.subtract(pos2, 1)

    blockexchange.set_pos(2, playername, pos2)
    blockexchange.api.get_schemamods(schema.id, function(mods)
      -- collect missing mods in a list
      local missing_mods = ""
      for modname in pairs(mods) do
        if not minetest.get_modpath(modname) then
          if #missing_mods > 0 then
            -- add comma separator
            missing_mods = missing_mods .. ","
          end
          missing_mods = missing_mods .. modname
        end
      end

      -- report schema stats
      local msg = "Total parts: " .. schema.total_parts ..
        " total size: " .. schema.total_size .. " bytes"

      -- report missing mods
      if #missing_mods > 0 then
        msg = msg .. " " .. minetest.colorize("#ff0000", "Missing mods: " .. missing_mods)
      end

      minetest.chat_send_player(playername, msg)
    end,
    function(http_code)
      local msg = "[blockexchange] get schemamods failed with http code: " .. (http_code or "unkown")
      minetest.log("error", msg)
      minetest.chat_send_player(playername, minetest.colorize("#ff0000", msg))
    end)
  end,
	function()
		minetest.chat_send_player(playername, "Schema not found: '" ..
			username .. "/" .. schemaname .. "'")
	end)
end
