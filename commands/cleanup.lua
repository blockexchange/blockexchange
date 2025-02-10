---------
-- async cleanup command

--- cleanup the given area
-- @param playername the playername to use in messages
-- @param pos1 lower position to emerge
-- @param pos2 upper position to emerge
-- @return a promise that resolves if the operation is complete
-- @return the job context
function blockexchange.cleanup(playername, pos1, pos2)
    local total_parts = blockexchange.count_schemaparts(pos1, pos2)
    local iterator = blockexchange.iterator(pos1, pos1, pos2)

    local ctx = {
        type = "cleanup",
        playername = playername,
        pos1 = pos1,
        pos2 = pos2,
        iterator = iterator,
        current_pos = iterator(),
        current_part = 0,
        progress_percent = 0,
        total_parts = total_parts,
        promise = Promise.new(),
        result = {
            meta = 0,
            param2 = 0
        }
    }

    -- start emerge worker with context
    blockexchange.cleanup_worker(ctx)

    return ctx.promise, ctx
end

minetest.register_chatcommand("bx_cleanup", {
	description = "Cleans up the selected region (stray metadata, invalid param2 values)",
  privs = { blockexchange = true },
	func = function(name)
    -- force-enable the hud
    blockexchange.set_player_hud(name, true)

    if blockexchange.get_job_context(name) then
      return true, "There is a job already running"
    end

    local pos1 = blockexchange.get_pos(1, name)
    local pos2 = blockexchange.get_pos(2, name)
    pos1, pos2 = blockexchange.sort_pos(pos1, pos2)

    if not pos1 or not pos2 then
      return false, "you need to set /bx_pos1 and /bx_pos2 first!"
    end

    local promise, ctx = blockexchange.cleanup(name, pos1, pos2)
    blockexchange.set_job_context(ctx.playername, ctx)

    promise:next(function(result)
      blockexchange.set_job_context(ctx.playername, nil)
      local msg = "[blockexchange] Cleanup complete, " ..
        "cleaned metadata: " .. result.meta .. ", cleaned param2: " .. result.param2
      minetest.log("action", msg)
      minetest.chat_send_player(name, msg)
    end):catch(function(err_msg)
      blockexchange.set_job_context(ctx.playername, nil)
      minetest.chat_send_player(name, minetest.colorize("#ff0000", err_msg))
    end)
		return true
  end
})
