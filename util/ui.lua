
-- namespace
local ui = {}
blockexchange.ui = ui

function ui.formspec(w, h)
    return [[
        formspec_version[3]
        size[]] .. w .. [[,]] .. h .. [[]
        no_prepend[]
        bgcolor[;neither;]
        background9[0,0;0,0;blockexchange_button_square_flat.png;true;8]
    ]]
end

function ui.button_exit(x,y,w,h,name,label)
    return "image_button_exit[" ..
        x..","..y..";"..w..","..h..";" ..
        "blockexchange_button_rectangle_depth_border.png;" ..
        name..";"..label..";" ..
        "true;false;" ..
        "blockexchange_button_rectangle_border.png" ..
        "]"
end

function ui.checkbox_on(x,y,name)
    return "image_button_exit[" ..
        x..","..y..";0.6,0.6;" ..
        "blockexchange_check_square_grey_checkmark.png;" ..
        name..";;" ..
        "true;false;" ..
        "]"
end

function ui.checkbox_off(x,y,name)
    return "image_button_exit[" ..
        x..","..y..";0.6,0.6;" ..
        "blockexchange_check_square_grey.png;" ..
        name..";;" ..
        "true;false;" ..
        "]"
end
