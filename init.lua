-- optional http instance
local http = minetest.request_http_api()

blockexchange = {
	-- online flag
	is_online = http ~= nil,
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

if not blockexchange.is_online then
	minetest.log("warning", "[blockexchange] the http api is not enabled, functionality is limited to local operations")
end

local MP = minetest.get_modpath("blockexchange")

-- http api
if blockexchange.is_online then
	loadfile(MP.."/api/info.lua")(http, blockexchange.url)
	loadfile(MP.."/api/schema.lua")(http, blockexchange.url)
	loadfile(MP.."/api/schemapart.lua")(http, blockexchange.url)
	loadfile(MP.."/api/schemamods.lua")(http, blockexchange.url)
	loadfile(MP.."/api/searchschema.lua")(http, blockexchange.url)
	loadfile(MP.."/api/token.lua")(http, blockexchange.url)
end

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
dofile(MP.."/areas.lua")

-- utils
dofile(MP.."/util/local_files.lua")
dofile(MP.."/util/check_api_compat.lua")
dofile(MP.."/util/get_schema_size.lua")
dofile(MP.."/util/sort_pos.lua")
dofile(MP.."/util/is_area_protected.lua")
dofile(MP.."/util/iterator_next.lua")

-- search
if blockexchange.is_online then
	dofile(MP.."/search/chat.lua")
	dofile(MP.."/search/formspec.lua")
end

-- commands
if blockexchange.is_online then
	dofile(MP.."/commands/api_check_wrapper.lua")
	dofile(MP.."/commands/info.lua")
	dofile(MP.."/commands/license.lua")
	dofile(MP.."/commands/user.lua")
	dofile(MP.."/commands/pos.lua")
	dofile(MP.."/commands/allocate_chat.lua")
	dofile(MP.."/commands/save_chat.lua")
	dofile(MP.."/commands/load_chat.lua")
end
dofile(MP.."/commands/allocate.lua")
dofile(MP.."/commands/allocate_local_chat.lua")
dofile(MP.."/commands/load.lua")
dofile(MP.."/commands/load_local_chat.lua")
dofile(MP.."/commands/save.lua")
dofile(MP.."/commands/save_local_chat.lua")
dofile(MP.."/commands/emerge.lua")
dofile(MP.."/commands/emerge_chat.lua")
dofile(MP.."/commands/protectioncheck.lua")

-- worker functions
dofile(MP.."/worker/load_worker.lua")
dofile(MP.."/worker/save_worker.lua")
dofile(MP.."/worker/emerge_worker.lua")
dofile(MP.."/worker/protectioncheck_worker.lua")

-- hud
dofile(MP.."/hud/progress.lua")
