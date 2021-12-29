
function blockexchange.protectioncheck(playername, pos1, pos2, schemaname)
  local total_parts = blockexchange.count_schemaparts(pos1, pos2)
  local iterator = blockexchange.iterator(pos1, pos1, pos2)

  local ctx = {
    type = "protectioncheck",
    playername = playername,
    pos1 = pos1,
    pos2 = pos2,
    iterator = iterator,
    current_pos = iterator(),
    current_part = 0,
    progress_percent = 0,
    total_parts = total_parts,
    schemaname = schemaname,
    description = "",
    promise = Promise.new()
  }

  -- start emerge worker with context
  blockexchange.protectioncheck_worker(ctx)

  return ctx.promise, ctx
end
