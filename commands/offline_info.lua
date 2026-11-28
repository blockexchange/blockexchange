
local offline_info_cmd = {
    description = "Blockexchange offline stub",
    func = function()
        return true, core.colorize("#ffff00", "The blockexchange mod has no access to the http api, " ..
            "to use the online functions add the 'blockexchange' mod to the 'secure.http_mods' setting")
    end
}

local online_commands = {
    "bx",
    "bx_login",
    "bx_logout",
    "bx_load",
    "bx_allocate",
    "bx_save",
    "bx_sync"
}

for _, name in ipairs(online_commands) do
    core.register_chatcommand(name, offline_info_cmd)
end