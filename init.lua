
local http = minetest.request_http_api()

if not http then
	minetest.log("error", "the 'blockexchange' mod needs access to the http api!")
	return
end


blockexchange = {
	api = {},
	api_version_major = 1,
	url = minetest.settings:get("blockexchange.url") or "https://blockexchange.minetest.land",
	min_delay = tonumber(minetest.settings:get("blockexchange.min_delay") or "0.2"),
	part_length = 16,
	-- maximum usage of microseconds per second for blockexchange processes
	max_cpu_micros_per_second = 50000,
	pos1 = {}, -- name -> pos
	pos2 = {} -- name -> pos
}

local MP = minetest.get_modpath("blockexchange")

-- http api
loadfile(MP.."/api/info.lua")(http, blockexchange.url)
loadfile(MP.."/api/schema.lua")(http, blockexchange.url)
loadfile(MP.."/api/schemapart.lua")(http, blockexchange.url)
loadfile(MP.."/api/schemamods.lua")(http, blockexchange.url)
loadfile(MP.."/api/searchschema.lua")(http, blockexchange.url)
loadfile(MP.."/api/token.lua")(http, blockexchange.url)

-- nodes
dofile(MP.."/nodes/controller.lua")
dofile(MP.."/nodes/placeholder.lua")

-- internal stuff
dofile(MP.."/privs.lua")
dofile(MP.."/markers.lua")
dofile(MP.."/token.lua")
dofile(MP.."/serialize.lua")
dofile(MP.."/deserialize.lua")
dofile(MP.."/license.lua")

-- utils
dofile(MP.."/util/sort_pos.lua")
dofile(MP.."/util/is_area_protected.lua")
dofile(MP.."/util/iterator_next.lua")

-- search
dofile(MP.."/search/chat.lua")
dofile(MP.."/search/formspec.lua")

-- commands
dofile(MP.."/commands/info.lua")
dofile(MP.."/commands/license.lua")
dofile(MP.."/commands/pos.lua")
dofile(MP.."/commands/user.lua")
dofile(MP.."/commands/allocate.lua")
dofile(MP.."/commands/allocate_chat.lua")
dofile(MP.."/commands/emerge.lua")
dofile(MP.."/commands/emerge_chat.lua")
dofile(MP.."/commands/upload.lua")
dofile(MP.."/commands/upload_chat.lua")
dofile(MP.."/commands/protectioncheck.lua")
dofile(MP.."/commands/download.lua")
dofile(MP.."/commands/download_chat.lua")

-- worker functions
dofile(MP.."/worker/download_worker.lua")
dofile(MP.."/worker/upload_worker.lua")
dofile(MP.."/worker/emerge_worker.lua")
dofile(MP.."/worker/protectioncheck_worker.lua")

-- hud
dofile(MP.."/hud.lua")

if minetest.settings:get_bool("blockexchange.enable_integration_test") then
	dofile(MP.."/integration_test.lua")
end
