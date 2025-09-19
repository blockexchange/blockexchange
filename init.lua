local MP = minetest.get_modpath("blockexchange")

-- optional http instance
local http = minetest.request_http_api and minetest.request_http_api()

-- global namespace
blockexchange = {
	-- online flag
	is_online = http ~= nil,
	mod_storage = minetest.get_mod_storage(),
	api = {},
	api_version_major = 1,
	url = minetest.settings:get("blockexchange.url") or "https://blockexchange.minetest.ch",
	min_delay = 0.1,
	pos1 = {}, -- name -> pos
	pos2 = {}, -- name -> pos
	max_size = 1000
}

-- min-delay for async operations
local min_delay_setting = tonumber(minetest.settings:get("blockexchange.min_delay"))
if min_delay_setting and min_delay_setting > 0 then
	-- use setting
	blockexchange.min_delay = min_delay_setting
elseif minetest.is_singleplayer() then
	-- default to 0 in singleplayer
	blockexchange.min_delay = 0
end

assert(mtzip.api_version == 1, "mtzip api compatibility")
assert(Promise.api_version == 1, "Promise api compatibility")

if not blockexchange.is_online then
	minetest.log("warning", "[blockexchange] the http api is not enabled, functionality is limited to local operations")
end

-- http api
if blockexchange.is_online then
	loadfile(MP.."/api/info.lua")(http, blockexchange.url)
	loadfile(MP.."/api/schema.lua")(http, blockexchange.url)
	loadfile(MP.."/api/schemapart.lua")(http, blockexchange.url)
	loadfile(MP.."/api/schemamods.lua")(http, blockexchange.url)
	loadfile(MP.."/api/login.lua")(http, blockexchange.url)
	loadfile(MP.."/api/token.lua")(http, blockexchange.url)
	loadfile(MP.."/api/media.lua")(http, blockexchange.url)
end

-- internal stuff
dofile(MP.."/jobcontext.lua")
dofile(MP.."/privs.lua")
dofile(MP.."/markers.lua")
dofile(MP.."/player_settings.lua")
dofile(MP.."/hud.lua")
dofile(MP.."/areas.lua")
dofile(MP.."/autosave.lua")

-- utils
dofile(MP.."/util/ui.lua")
dofile(MP.."/util/pointed.lua")
dofile(MP.."/util/placer_tool.lua")
dofile(MP.."/util/placer_entity.lua")
dofile(MP.."/util/placer_preview.lua")
dofile(MP.."/util/remove_nodes.lua")
dofile(MP.."/util/player_area.lua")
dofile(MP.."/util/compare_area.lua")
dofile(MP.."/util/cleanup_area.lua")
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
dofile(MP.."/util/token.lua")
dofile(MP.."/util/clip_area.lua")
dofile(MP.."/util/is_area_protected.lua")
dofile(MP.."/util/get_base_pos.lua")
dofile(MP.."/util/iterator.lua")
dofile(MP.."/util/log.lua")
dofile(MP.."/util/collect_node_count.lua")
dofile(MP.."/util/check_size.lua")
dofile(MP.."/util/count_schemaparts.lua")
dofile(MP.."/util/unpack_schemapart.lua")
dofile(MP.."/util/place_schemapart.lua")
dofile(MP.."/util/validate_name.lua")
dofile(MP.."/util/is_player_in_area.lua")
dofile(MP.."/util/create_schemapart.lua")

if blockexchange.is_online then
	-- online commands
	dofile(MP.."/commands/info.lua")
	dofile(MP.."/commands/license.lua")
	dofile(MP.."/commands/user.lua")
	dofile(MP.."/commands/placer.lua")
	dofile(MP.."/commands/save.lua")
	dofile(MP.."/commands/save_update.lua")
	dofile(MP.."/commands/autosave.lua")
	dofile(MP.."/commands/media.lua")
	dofile(MP.."/commands/load.lua")
	dofile(MP.."/commands/bx.lua")
else
	dofile(MP.."/commands/offline_info.lua")
end
-- commands
dofile(MP.."/commands/pos.lua")
dofile(MP.."/commands/area.lua")
dofile(MP.."/commands/cancel_chat.lua")
dofile(MP.."/commands/allocate.lua")
dofile(MP.."/commands/load_local.lua")
dofile(MP.."/commands/save_local.lua")
dofile(MP.."/commands/emerge.lua")
dofile(MP.."/commands/protectioncheck.lua")
dofile(MP.."/commands/cleanup.lua")

-- compat
if minetest.get_modpath("advtrains") then
	dofile(MP.."/compat/advtrains.lua")
end

if minetest.get_modpath("nc_api_storebox") then
	dofile(MP.."/compat/nodecore.lua")
end

-- testing
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
