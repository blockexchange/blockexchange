---------
-- jwt token utilities

local META_KEY = "blockexchange_token"

-- http://lua-users.org/wiki/BaseSixtyFour
local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

--- decode a base64 string into a string
-- @param the data in base64 format
-- @return the decoded string
-- TODO: check if minetest.decode_base64 can work here
local function dec(data)
	data = string.gsub(data, '[^'..b..'=]', '')
	return (data:gsub('.', function(x)
		if (x == '=') then return '' end
		local r,f='',(b:find(x)-1)
		for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
		return r;
	end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
		if (#x ~= 8) then return '' end
		local c=0
		for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
		return string.char(c)
	end))
end

--- parses a jwt token
-- @param the token in string format
-- @return the payload in json format
function blockexchange.parse_token(token)
	-- header.payload.signature
	local _, _, _, payload_json = string.find(token, "^([^.]+).([^.]+).([^.]+)$")
	local json = dec(payload_json)
	local payload = minetest.parse_json(json)
	return payload
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