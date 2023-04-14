local MP = minetest.get_modpath("blockexchange")

-- optional http instance
local http = minetest.request_http_api()

-- global namespace
blockexchange = {
	-- online flag
	is_online = http ~= nil,
	mod_storage = minetest.get_mod_storage(),
	api = {},
	api_version_major = 1,
	url = minetest.settings:get("blockexchange.url") or "https://blockexchange.minetest.ch",
	min_delay = tonumber(minetest.settings:get("blockexchange.min_delay") or "0.1"),
	pos1 = {}, -- name -> pos
	pos2 = {} -- name -> pos
}

if not blockexchange.is_online then
	minetest.log("warning", "[blockexchange] the http api is not enabled, functionality is limited to local operations")
end

-- http api
if blockexchange.is_online then
	loadfile(MP.."/api/util.lua")(http, blockexchange.url)
	loadfile(MP.."/api/info.lua")(http, blockexchange.url)
	loadfile(MP.."/api/schema.lua")(http, blockexchange.url)
	loadfile(MP.."/api/schemapart.lua")(http, blockexchange.url)
	loadfile(MP.."/api/schemamods.lua")(http, blockexchange.url)
	loadfile(MP.."/api/token.lua")(http, blockexchange.url)
end

-- internal stuff
dofile(MP.."/jobcontext.lua")
dofile(MP.."/privs.lua")
dofile(MP.."/markers.lua")
dofile(MP.."/token.lua")
dofile(MP.."/license.lua")
dofile(MP.."/hud.lua")
dofile(MP.."/areas.lua")
-- dofile(MP.."/autosave.lua")

-- utils
dofile(MP.."/util/player_area.lua")
dofile(MP.."/util/compare_area.lua")
dofile(MP.."/util/ignored_content_ids.lua")
dofile(MP.."/util/serialize.lua")
dofile(MP.."/util/deserialize.lua")
dofile(MP.."/util/local_files.lua")
dofile(MP.."/util/check_api_compat.lua")
dofile(MP.."/util/get_schema_size.lua")
dofile(MP.."/util/get_mapblock.lua")
dofile(MP.."/util/sort_pos.lua")
dofile(MP.."/util/get_mapblock_bounds_from_mapblock.lua")
dofile(MP.."/util/schemapart_offset.lua")
dofile(MP.."/util/clip_area.lua")
dofile(MP.."/util/is_area_protected.lua")
dofile(MP.."/util/get_base_pos.lua")
dofile(MP.."/util/iterator.lua")
dofile(MP.."/util/collect_node_count.lua")
dofile(MP.."/util/count_schemaparts.lua")
dofile(MP.."/util/unpack_schemapart.lua")
dofile(MP.."/util/place_schemapart.lua")
dofile(MP.."/util/validate_name.lua")
dofile(MP.."/util/is_player_in_area.lua")

-- commands
if blockexchange.is_online then
	dofile(MP.."/commands/api_check_wrapper.lua")
	dofile(MP.."/commands/info.lua")
	dofile(MP.."/commands/license.lua")
	dofile(MP.."/commands/user.lua")
	dofile(MP.."/commands/allocate_chat.lua")
	dofile(MP.."/commands/save_chat.lua")
	dofile(MP.."/commands/save_update_chat.lua")
	dofile(MP.."/commands/load_update_chat.lua")
	dofile(MP.."/commands/load_chat.lua")
end
dofile(MP.."/commands/pos.lua")
dofile(MP.."/commands/area.lua")
dofile(MP.."/commands/cancel_chat.lua")
dofile(MP.."/commands/allocate.lua")
dofile(MP.."/commands/allocate_local_chat.lua")
dofile(MP.."/commands/load.lua")
dofile(MP.."/commands/load_local_chat.lua")
dofile(MP.."/commands/save.lua")
dofile(MP.."/commands/save_update.lua")
dofile(MP.."/commands/save_local_chat.lua")
dofile(MP.."/commands/emerge.lua")
dofile(MP.."/commands/emerge_chat.lua")
dofile(MP.."/commands/protectioncheck.lua")

-- worker functions
dofile(MP.."/worker/load_worker.lua")
dofile(MP.."/worker/save_worker.lua")
dofile(MP.."/worker/save_update_worker.lua")
dofile(MP.."/worker/emerge_worker.lua")
dofile(MP.."/worker/protectioncheck_worker.lua")

if minetest.get_modpath("mtt") then
	dofile(MP .. "/mtt/serialize_spec.lua")
	dofile(MP .. "/mtt/token_spec.lua")
	dofile(MP .. "/mtt/areas_spec.lua")
	dofile(MP .. "/mtt/clip_area_spec.lua")
	dofile(MP .. "/mtt/get_base_pos_spec.lua")
	dofile(MP .. "/mtt/iterator_spec.lua")
	dofile(MP .. "/mtt/schemapart_offset_spec.lua")
	dofile(MP .. "/mtt/sort_pos_spec.lua")
	dofile(MP .. "/mtt/validate_name_spec.lua")
	dofile(MP .. "/mtt/load_save.spec.lua")
end