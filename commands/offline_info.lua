
local offline_info_cmd = {
    description = "Blockexchange offline stub",
    func = function()
        return true, minetest.colorize("#ffff00", "The blockexchange mod has no access to the http api, " ..
            "to use the online functions add the 'blockexchange' mod to the 'secure.http_mods' setting")
    end
}

local online_commands = {
    "bx",
    "bx_login",
    "bx_logout",
    "bx_load",
    "bx_load_update",
    "bx_allocate",
    "bx_save",
    "bx_save_update"
}

for _, name in ipairs(online_commands) do
    minetest.register_chatcommand(name, offline_info_cmd)
end