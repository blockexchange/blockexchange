---------
-- async emerge command


--- emerge the given area
-- @param playername the playername to use in messages
-- @param pos1 lower position to emerge
-- @param pos2 upper position to emerge
-- @return a promise that resolves if the operation is complete
-- @return the job context
function blockexchange.emerge(playername, pos1, pos2)
  local total_parts = blockexchange.count_schemaparts(pos1, pos2)
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

  return ctx.promise, ctx
end
