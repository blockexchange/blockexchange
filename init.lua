
local http = minetest.request_http_api()

if not http then
  error("the 'blockexchange' mod needs access to the http api!")
end


blockexchange = {
	api_version_major = 1,
  http = http,
  url = minetest.settings:get("blockexchange.url") or "https://blockexchange.minetest.land",
  part_length = 16,
  pos1 = {}, -- name -> pos
  pos2 = {} -- name -> pos
}

local MP = minetest.get_modpath("blockexchange")
dofile(MP.."/api.lua")
dofile(MP.."/common.lua")
dofile(MP.."/iterator.lua")
dofile(MP.."/serialize.lua")
dofile(MP.."/chat.lua")
dofile(MP.."/chat_pos.lua")
dofile(MP.."/upload.lua")
dofile(MP.."/upload_worker.lua")
dofile(MP.."/download.lua")
dofile(MP.."/download_worker.lua")

-- clear http reference from global scope
blockexchange.http = nil

if minetest.settings:get("enable_blockexchange_integration_test") then
	dofile(MP.."/integration_test.lua")
end
