
local http = minetest.request_http_api()

if not http then
  minetest.log("error", "the 'blockexchange' mod needs access to the http api!")
  return
end


blockexchange = {
  api = {},
  api_version_major = 1,
  http = http,
  url = minetest.settings:get("blockexchange.url") or "https://blockexchange.minetest.land",
  part_length = 16,
  -- maximum usage of microseconds per second for blockexchange processes
  max_cpu_micros_per_second = 50000,
  pos1 = {}, -- name -> pos
  pos2 = {} -- name -> pos
}

local MP = minetest.get_modpath("blockexchange")

-- http api
dofile(MP.."/api/info.lua")
dofile(MP.."/api/schema.lua")
dofile(MP.."/api/schemapart.lua")
dofile(MP.."/api/schemamods.lua")
dofile(MP.."/api/searchschema.lua")
dofile(MP.."/api/token.lua")

-- clear http reference from global scope
blockexchange.http = nil

-- internal stuff
dofile(MP.."/privs.lua")
dofile(MP.."/markers.lua")
dofile(MP.."/token.lua")
dofile(MP.."/serialize.lua")
dofile(MP.."/license.lua")

-- process handling
dofile(MP.."/process/register.lua")
dofile(MP.."/process/scheduler.lua")

-- utils
dofile(MP.."/util/sort_pos.lua")
dofile(MP.."/util/is_area_protected.lua")
dofile(MP.."/util/iterator_next.lua")

-- search
dofile(MP.."/search/chat.lua")
dofile(MP.."/search/formspec.lua")

-- commands
dofile(MP.."/commands/info.lua")
dofile(MP.."/commands/ps.lua")
dofile(MP.."/commands/kill.lua")
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

-- nodes
dofile(MP.."/nodes/controller.lua")
dofile(MP.."/nodes/placeholder.lua")
