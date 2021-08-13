local FIELD_KEY = "blockexchange_tracking"

function blockexchange.set_tracking(playername, enabled)
	local player = minetest.get_player_by_name(playername)
	if player then
        local value = 0
        if enabled then
            value = 1
        end
		player:get_meta():set_int(FIELD_KEY, value)
	end
end

function blockexchange.get_tracking(playername)
	local player = minetest.get_player_by_name(playername)
	if player then
		local value = player:get_meta():get_int(FIELD_KEY)
		return value == 1
	end
end