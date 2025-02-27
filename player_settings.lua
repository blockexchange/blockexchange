
function blockexchange.get_player_settings(playername)
    local str = blockexchange.mod_storage:get_string("settings_" .. playername)
    if not str or str == "" then
        -- defaults
        return {
            license = "CC0"
        }
    else
        -- stored settings
        return minetest.deserialize(str)
    end
end

function blockexchange.set_player_settings(playername, settings)
    blockexchange.mod_storage:set_string("settings_" .. playername, minetest.serialize(settings))
end
