

minetest.register_chatcommand("bx_license", {
	description = "Shows or sets your currently set license",
	func = function(name, license)

		if license and license ~= "" then
			blockexchange.licenses[name] = license
			blockexchange.persist_licenses()
		end

		return true, "Your default license: " .. (blockexchange.licenses[name] or "CC0")
  end
})
