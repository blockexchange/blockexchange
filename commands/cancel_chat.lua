
minetest.register_chatcommand("bx_cancel", {
  description = "Cancels the current blockexchange job",
  func = function(name, param)
    local jobs = blockexchange.get_jobs(name)
    if #jobs == 0 then
      return true, "No job running, nothing canceled"
    end

    local job = jobs[tonumber(param)]
    if not job then
      return true, "Job with number '" .. param .. "' not found"
    end

    job.cancel = true
    return true, "canceled job #" .. param
  end
})
