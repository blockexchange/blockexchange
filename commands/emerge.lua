
function blockexchange.emerge(playername, pos1, pos2)
  local total_parts =
    math.ceil(math.abs(pos1.x - pos2.x) / blockexchange.part_length) *
    math.ceil(math.abs(pos1.y - pos2.y) / blockexchange.part_length) *
    math.ceil(math.abs(pos1.z - pos2.z) / blockexchange.part_length)

  local iterator = blockexchange.iterator(pos1, pos1, pos2)

  local ctx = {
    type = "emerge",
    playername = playername,
    pos1 = pos1,
    pos2 = pos2,
    iterator = iterator,
    current_pos = iterator(),
    current_part = 0,
    progress_percent = 0,
    total_parts = total_parts,
    promise = Promise.new()
  }

  -- start emerge worker with context
  blockexchange.emerge_worker(ctx)

  return ctx.promise
end
