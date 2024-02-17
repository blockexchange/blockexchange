local FORMNAME = "bx_main"

local function area_fs(player, pos)
    local area = blockexchange.get_area(pos)
    if not area then
        return ""
    end

    print(dump(area))

    return [[
        label[2,2;Area selected]
    ]]
end

function blockexchange.ui.main(playername)
    local player = minetest.get_player_by_name(playername)
    if not player then
        return
    end
    local pos = player:get_pos()

    local fs = [[
        formspec_version[2]
        size[8,9]
        ]] .. area_fs(player, pos) .. [[
        button_exit[4,8;4,1;quit;Exit]
    ]]
    print(fs)
    minetest.show_formspec(playername, FORMNAME, fs)
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= FORMNAME then
        return
    end
end)

