
minetest.register_chatcommand("bx_save_update", {
  description = "Updates the selected region to the blockexchange server",
  privs = { blockexchange = true },
  func = blockexchange.api_check_wrapper(function(name)

    local token = blockexchange.get_token(name)
    if not token then
      -- TODO check validity
      return true, "Please login first to upload a schematic"
    end

    local pos1 = blockexchange.get_pos(1, name)
    local pos2 = blockexchange.get_pos(2, name)

    if not pos1 or not pos2 then
      return true, "you need to set /bx_pos1 and /bx_pos2 first!"
    end

    -- sort positions
    pos1, pos2 = blockexchange.sort_pos(pos1, pos2)

    local area = blockexchange.get_area(pos1, pos2)
    if area then
      -- clip to area
      pos1 = {
        x = math.max(pos1.x, area.pos1.x),
        y = math.max(pos1.y, area.pos1.y),
        z = math.max(pos1.z, area.pos1.z)
      }
      pos2 = {
        x = math.min(pos2.x, area.pos2.x),
        y = math.min(pos2.y, area.pos2.y),
        z = math.min(pos2.z, area.pos2.z)
      }

      local relative_start_pos = vector.subtract(pos1, area.pos1)

      return true, dump(relative_start_pos) .. dump(pos2)
    end

    return true, "no blockexchange area found in the selected region"
  end)
})
