
local http = minetest.request_http_api()

if not http then
  error("the 'blockexchange' mod needs access to the http api!")
end


blockexchange = {
  api = {},
	api_version_major = 1,
  http = http,
  url = minetest.settings:get("blockexchange.url") or "https://blockexchange.minetest.land",
  part_length = 16,
  pos1 = {}, -- name -> pos
  pos2 = {} -- name -> pos
}

if minetest.get_modpath("worldedit") then
  -- use WE's positions
  blockexchange.pos1 = worldedit.pos1
  blockexchange.pos2 = worldedit.pos2
end

local MP = minetest.get_modpath("blockexchange")

-- http api
dofile(MP.."/api/info.lua")
dofile(MP.."/api/register.lua")
dofile(MP.."/api/schema.lua")
dofile(MP.."/api/schemapart.lua")
dofile(MP.."/api/schemamods.lua")
dofile(MP.."/api/searchschema.lua")
dofile(MP.."/api/token.lua")

-- clear http reference from global scope
blockexchange.http = nil

-- internal stuff
dofile(MP.."/placeholder_node.lua")
dofile(MP.."/privs.lua")
dofile(MP.."/common.lua")
dofile(MP.."/token.lua")
dofile(MP.."/iterator.lua")
dofile(MP.."/serialize.lua")

-- common chat commands
dofile(MP.."/chat_info.lua")
dofile(MP.."/chat_pos.lua")
dofile(MP.."/chat_user.lua")

-- search
dofile(MP.."/search/chat.lua")
dofile(MP.."/search/formspec.lua")

-- commands
dofile(MP.."/commands/allocate.lua")
dofile(MP.."/commands/allocate_chat.lua")
dofile(MP.."/commands/emerge.lua")
dofile(MP.."/commands/emerge_chat.lua")
dofile(MP.."/commands/emerge_worker.lua")
dofile(MP.."/commands/upload.lua")
dofile(MP.."/commands/upload_chat.lua")
dofile(MP.."/commands/upload_worker.lua")
dofile(MP.."/commands/download.lua")
dofile(MP.."/commands/download_chat.lua")
dofile(MP.."/commands/download_worker.lua")

-- controller
dofile(MP.."/controller.lua")
