
minetest.register_chatcommand("bx_cancel", {
  description = "Cancels the current blockexchange job",
  func = function(name)
    local ctx = blockexchange.get_job_context(name)
    if not ctx then
      return true, "No job running, nothing canceled"
    end

    ctx.cancel = true

    return true, "canceled job of type: " .. ctx.type
  end
})
