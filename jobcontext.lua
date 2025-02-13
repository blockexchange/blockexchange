---------
-- job context utilities

local job_context_map = {}

--- sets the current job context for the player
-- @param playername the name of the player
-- @param ctx the job context for the worker
-- @param promise the job's promise, for cleanup/removal of the job-data
-- @return the payload in json format
function blockexchange.set_job_context(playername, ctx, promise)
    job_context_map[playername] = ctx
    if promise then
        promise:finally(function()
            job_context_map[playername] = nil
        end)
    end
end

--- returns the current job context for the player, nil if no job active
-- @param playername the name of the player
-- @return the current job contect
function blockexchange.get_job_context(playername)
    return job_context_map[playername]
end

--- returns all job contexts
-- @return the job context map with playername as key
function blockexchange.get_job_contexts()
    return job_context_map
end