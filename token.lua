---------
-- jwt token utilities

local META_KEY = "blockexchange_token"

--- parses a jwt token
-- @param the token in string format
-- @return the payload in json format
function blockexchange.parse_token(token)
	-- header.payload.signature
	local _, _, _, payload_json = string.find(token, "^([^.]+).([^.]+).([^.]+)$")
	local json = minetest.decode_base64(payload_json)
	local payload = minetest.parse_json(json)
	return payload
end

--- returns the claims for the playername as table
-- @param playername the name of the player
-- @return the claims for the player or an empty table
function blockexchange.get_claims(playername)
	local token = blockexchange.get_token(playername)
	local claims = blockexchange.parse_token(token)
	return claims or {}
end

--- returns the token for the player in base64 format or nil if not present
-- @param playername the name of the player (has to be online in order to work)
-- @return the token in string/base64 format
function blockexchange.get_token(playername)
	local player = minetest.get_player_by_name(playername)
	if not player then
		-- player not online
		return
	end

	local meta = player:get_meta()
	local token = meta:get_string(META_KEY)

	if not token or token == "" then
		-- no token stored
		return
	end

	return token
end

--- sets the token for the player or clears it if nil
-- @param playername the name of the player (has to be online in order to work)
-- @param token the token to set (in base64/string format)
function blockexchange.set_token(playername, token)
	local player = minetest.get_player_by_name(playername)
	if not player then
		-- player not online
		return
	end

	local meta = player:get_meta()
	meta:set_string(META_KEY, token or "")
end