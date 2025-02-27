

minetest.register_chatcommand("bx_license", {
	description = "Shows or sets your currently set license",
	func = function(name, license)
		local player_settings = blockexchange.get_player_settings(name)

		if license and license ~= "" then
			player_settings.license = license
			blockexchange.set_player_settings(name, player_settings)
		end

		return true, "Your default license: " .. player_settings.license
  end
})
