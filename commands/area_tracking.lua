
minetest.register_chatcommand("bx_tracking", {
	description = "enables or disables the area tracking: [on|off]",
	func = function(name, value)
		local enabled = value == "on"

		blockexchange.set_tracking(name, enabled)

		if enabled then
			return true, "Tracking enabled"
		else
			return true, "Tracking disabled"
		end
  end
})
