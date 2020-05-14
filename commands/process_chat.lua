

minetest.register_chatcommand("bx_ps", {
	description = "Shows the current blockexchange processes",
	func = function()
    local msg = ""
    for _, ctx in ipairs(blockexchange.processes) do
      msg = "+ " .. ctx.type .. " by '" .. msg.playername .. "'"
    end
		return true, msg
  end
})
