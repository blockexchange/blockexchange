
local http = minetest.request_http_api()

if not http then
  error("the 'blockexchange' mod needs access to the http api!")
end


blockexchange = {
	api_version_major = 1,
  http = http,
  url = minetest.settings:get("blockexchange.url") or "https://blockexchange.minetest.land",
  part_length = 16
}

local MP = minetest.get_modpath("blockexchange")
dofile(MP.."/api.lua")
dofile(MP.."/iterator.lua")
dofile(MP.."/serialize.lua")
dofile(MP.."/chat.lua")
dofile(MP.."/upload.lua")
dofile(MP.."/upload_worker.lua")
dofile(MP.."/download.lua")
dofile(MP.."/download_worker.lua")

-- clear http reference from global scope
blockexchange.http = nil

if not minetest.get_modpath("worldedit") then
	minetest.log("warning", "Using embedded worldedit dependency!")
	worldedit = {
		pos1 = {},
		pos2 = {}
	}
	dofile(MP.."/embedded/worldedit.lua")
	dofile(MP.."/embedded/common.lua")
	dofile(MP.."/embedded/chat.lua")
end

if minetest.settings:get("enable_blockexchange_integration_test") then
	dofile(MP.."/integration_test.lua")
end
