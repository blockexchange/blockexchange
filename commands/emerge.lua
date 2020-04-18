
function blockexchange.emerge(playername, pos1, pos2)
  local total_parts =
    math.ceil(math.abs(pos1.x - pos2.x) / blockexchange.part_length) *
    math.ceil(math.abs(pos1.y - pos2.y) / blockexchange.part_length) *
    math.ceil(math.abs(pos1.z - pos2.z) / blockexchange.part_length)

  local ctx = {
    type = "emerge",
    playername = playername,
    pos1 = pos1,
    pos2 = pos2,
    current_pos = table.copy(pos1),
    current_part = 0,
    progress_percent = 0,
    total_parts = total_parts
  }

  table.insert(blockexchange.processes, ctx)

  -- start emerge worker with context
  minetest.after(0, blockexchange.emerge_worker, ctx)

  return ctx
end