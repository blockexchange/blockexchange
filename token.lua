
-- name -> token
blockexchange.tokens = {}

function blockexchange.persist_tokens()
	local file = io.open(minetest.get_worldpath() .. "/blockexchange_tokens","w")
	local json = minetest.write_json(blockexchange.tokens)
	if file and file:write(json) and file:close() then
		return
	else
		minetest.log("error","[blockexchange] token persist failed!")
		return
	end
end

function blockexchange.load_tokens()
	local file = io.open(minetest.get_worldpath() .. "/blockexchange_tokens","r")

	if file then
		local json = file:read("*a")
		blockexchange.tokens = minetest.parse_json(json or "") or {}
	end
end

-- http://lua-users.org/wiki/BaseSixtyFour
local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

-- decoding
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

function blockexchange.parse_token(token)
	-- header.payload.signature
	local _, _, _, payload_json = string.find(token, "^([^.]+).([^.]+).([^.]+)$")
	local json = dec(payload_json)
	local payload = minetest.parse_json(json)
	return payload
end

blockexchange.load_tokens()
