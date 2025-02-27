---------
-- jwt token utilities

--- parses a jwt token
-- @param the token in string format
-- @return the payload in json format
function blockexchange.parse_token(token)
	-- header.payload.signature
	if not token or token == "" then
		-- return if no token available
		return
	end
	local _, _, _, payload_json = string.find(token, "^([^.]+).([^.]+).([^.]+)$")
	local json = minetest.decode_base64(payload_json)
	local payload = minetest.parse_json(json)
	return payload
end

function blockexchange.check_expiration(current_time, claims)
	return claims.exp > current_time
end

--- returns the claims for the playername as table
-- @param playername the name of the player
-- @return the claims for the player or nil
function blockexchange.get_claims(playername)
	local player_settings = blockexchange.get_player_settings(playername)
	local claims = blockexchange.parse_token(player_settings.token)
	return claims
end
