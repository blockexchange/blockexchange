---------
-- jwt token utilities

-- map of playername => token
-- TODO: periodical cleanup of expired tokens
local tokens = {}

local function save_tokens()
	blockexchange.mod_storage:set_string("tokens", minetest.serialize(tokens))
end

local function load_tokens()
	tokens = minetest.deserialize(blockexchange.mod_storage:get_string("tokens")) or {}
end

-- load the stored tokens
load_tokens()

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
	local token = blockexchange.get_token(playername)
	local claims = blockexchange.parse_token(token)
	return claims
end

--- returns the token for the player in base64 format or nil if not present
-- @param playername the name of the player
-- @return the token in string/base64 format
function blockexchange.get_token(playername)
	local token = tokens[playername]
	if not token or token == "" then
		-- no token stored
		return
	end

	return token
end

--- sets the token for the player or clears it if nil
-- @param playername the name of the player
-- @param token the token to set (in base64/string format)
function blockexchange.set_token(playername, token)
	tokens[playername] = token
	save_tokens()
end