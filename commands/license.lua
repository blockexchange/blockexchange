

minetest.register_chatcommand("bx_license", {
	description = "Shows or sets your currently set license",
	func = function(name, license)

		if license and license ~= "" then
			blockexchange.set_license(name, license)
		end

		return true, "Your default license: " .. (license or "CC0")
  end
})
