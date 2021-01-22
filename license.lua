
-- name -> license
blockexchange.licenses = {}

function blockexchange.persist_licenses()
	local file = io.open(minetest.get_worldpath() .. "/blockexchange_licenses","w")
	local json = minetest.write_json(blockexchange.licenses)
	if file and file:write(json) and file:close() then
		return
	else
		minetest.log("error","[blockexchange] license persist failed!")
		return
	end
end

function blockexchange.load_tokens()
	local file = io.open(minetest.get_worldpath() .. "/blockexchange_licenses","r")

	if file then
		local json = file:read("*a")
		blockexchange.licenses = minetest.parse_json(json or "") or {}
	end
end


blockexchange.load_tokens()
