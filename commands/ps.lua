

minetest.register_chatcommand("bx_ps", {
	description = "Shows the current blockexchange processes",
	func = function()
    local msg = ""
		local now = os.time()

    for _, ctx in ipairs(blockexchange.processes) do
			local runtime_seconds = now - ctx._meta.start_time
      msg = "+ [" .. ctx._meta.id .. "]" ..
				" Type" .. ctx.type ..
				" Owner '" .. msg.playername .. "'" ..
				" Runtime: " .. runtime_seconds .. " s"
    end
		return true, msg
  end
})
