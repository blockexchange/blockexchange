local FIELD_KEY = "blockexchange_license"

function blockexchange.set_license(playername, license)
	local player = minetest.get_player_by_name(playername)
	if player then
		player:get_meta():set_string(FIELD_KEY, license)
	end
end

function blockexchange.get_license(playername)
	local player = minetest.get_player_by_name(playername)
	if player then
		local license = player:get_meta():get_string(FIELD_KEY)
		if license and license ~= "" then
			return license
		end
	end

	-- default to CC0
	return "CC0"
end