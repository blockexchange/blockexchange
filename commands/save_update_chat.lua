
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
    if not area then
      return true, "no blockexchange area found in the selected region"
    end

    -- get mapblock granular offsets
    local offset_pos1 = blockexchange.get_schemapart_offset(area.data.origin, pos1)
    local _, offset_pos2 = blockexchange.get_schemapart_offset(area.data.origin, pos2)

    -- calculate absoulte positions
    local abs_pos1 = vector.add(area.data.origin, offset_pos1)
    local abs_pos2 = vector.add(area.data.origin, offset_pos2)

    -- clip to area bounds
    abs_pos1, abs_pos2 = blockexchange.clip_area(area.pos1, area.pos2, abs_pos1, abs_pos2)

    -- upload all schemaparts in offset region
    blockexchange.save_update(
      name, area.data.origin, abs_pos1, abs_pos2,
      area.data.username, area.data.schemaname
    )

    return true
  end)
})
