
minetest.register_chatcommand("bx_save_local", {
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

    -- kick off upload with local-save flag
    blockexchange.save(name, pos1, pos2, schemaname, true)

    return true
  end
})

