
local http = minetest.request_http_api()

if not http then
  error("the 'blockexchange' mod needs access to the http api!")
end


blockexchange = {
  http = http,
  url = minetest.settings:get("blockexchange.url") or "https://blockexchange.minetest.land",
  part_length = 10
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


-- test stuff
--[[
minetest.register_on_mods_loaded(function()
  local pos1 = { x=0, y=0, z=0 }
  local pos2 = { x=20, y=20, z=20 }
  minetest.after(0, function()
    minetest.emerge_area(pos1, pos2, function(_, _, calls_remaining)
      minetest.log("action", "Emerge-calls remaining: " .. calls_remaining)
      if calls_remaining == 0 then
        minetest.log("action", "done!")
        blockexchange.upload(pos1, pos2)
      end
    end)
  end)
end)
--]]
