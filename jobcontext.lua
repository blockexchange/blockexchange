
local job_map = {} -- playername -> {job, job, ...}

--- adds a job for the player
function blockexchange.add_job(playername, job)
    assert(type(job.hud_icon) == "string", "job.hud_icon is a string")
    assert(type(job.hud_text) == "string", "job.hud_text is a string")
    assert(Promise.is_promise(job.promise), "job.promise is a promise object")

    -- force-enable the hud for the player
    blockexchange.set_player_hud(playername, true)

    local jobs = job_map[playername]
    if not jobs then
        jobs = {}
        job_map[playername] = jobs
    end

    -- remove job when done
    job.promise:finally(function()
        for i, j in ipairs(jobs) do
            if j == job then
                -- job found, remove from table
                table.remove(jobs, i)
                break
            end
        end
    end)

    table.insert(jobs, job)
end

--- returns all jobs for the player
function blockexchange.get_jobs(playername)
    return job_map[playername] or {}
end
