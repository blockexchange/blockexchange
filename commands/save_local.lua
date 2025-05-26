
function blockexchange.save_local(playername, pos1, pos2, schemaname)
  pos1, pos2 = blockexchange.sort_pos(pos1, pos2)
	local player_settings = blockexchange.get_player_settings(playername)

  local job = {
    hud_icon = "blockexchange_upload.png",
    hud_text = "Saving local '" .. schemaname .. "'"
  }

  local schema = {
		size_x = pos2.x - pos1.x + 1,
		size_y = pos2.y - pos1.y + 1,
		size_z = pos2.z - pos1.z + 1,
		description = "",
		license = player_settings.license,
		name = schemaname
	}

  local zipfile = io.open(blockexchange.get_local_filename(schemaname), "wb")
  local zip = mtzip.zip(zipfile)

  local mod_names = {}
  local total_size = 0
  local total_parts = 0

  job.promise = Promise.async(function(await)
    for current_pos, relative_pos, progress in blockexchange.iterator(pos1, pos1, pos2) do
      local current_pos2 = vector.add(current_pos, 15)
      current_pos2.x = math.min(current_pos2.x, pos2.x)
      current_pos2.y = math.min(current_pos2.y, pos2.y)
      current_pos2.z = math.min(current_pos2.z, pos2.z)

      local progress_percent = math.floor(progress * 100 * 10) / 10
      job.hud_text = "Saving local '" .. schemaname .. "', progress: " .. progress_percent .. " %"

      local data, node_count, air_only = blockexchange.serialize_part(current_pos, current_pos2)
      blockexchange.collect_node_count(node_count, mod_names)

      if not air_only then
        local schemapart = await(blockexchange.create_schemapart(data, relative_pos))

        total_size = total_size + #schemapart.data + #schemapart.metadata
        total_parts = total_parts + 1

        minetest.log("action", "[blockexchange] Saving local schemapart " .. minetest.pos_to_string(relative_pos))
        local filename = "schemapart_" .. schemapart.offset_x ..
          "_" .. schemapart.offset_y ..
          "_" .. schemapart.offset_z ..
          ".json"
        zip:add(filename, minetest.write_json(schemapart))
      end

      if job.cancel then
        error("canceled", 0)
      end

      await(Promise.after(blockexchange.min_delay))
    end

    -- create an array with mod names
		local mod_name_list = {}
		for k in pairs(mod_names) do
			table.insert(mod_name_list, k)
		end

    schema.total_parts = total_parts
    schema.total_size = total_size
    zip:add("mods.json", minetest.write_json(mod_names))
    zip:add("schema.json", minetest.write_json(schema))

    return {
      total_size = total_size,
      total_parts = total_parts,
      mod_names = mod_names
    }
  end)

  job.promise:finally(function()
    -- cleanup
    zip:close()
		zipfile:close()
  end)

  blockexchange.add_job(playername, job)
  return job.promise
end

Promise.register_chatcommand("bx_save_local", {
  params = "<name>",
  privs = { blockexchange = true },
  description = "Saves the selected region to the disk",
  func = function(name, schemaname)
    if not schemaname or schemaname == "" then
      return true, "Usage: /bx_save_local <schemaname>"
    end

    local pos1 = blockexchange.get_pos(1, name)
    local pos2 = blockexchange.get_pos(2, name)

    if not pos1 or not pos2 then
      return true, "you need to set /bx_pos1 and /bx_pos2 first!"
    end

    return blockexchange.save_local(name, pos1, pos2, schemaname):next(function(result)
      return "Local save complete with " .. result.total_parts .. " parts and " .. result.total_size .. " bytes"
    end)
  end
})

