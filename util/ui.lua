
-- namespace
local ui = {}
blockexchange.ui = ui

function ui.formspec(w, h)
    return [[
        formspec_version[3]
		size[]] .. w .. [[,]] .. h .. [[]
		no_prepend[]
		background9[0,0;0,0;blockexchange_button_square_flat.png;true;8]
    ]]
end

function ui.button(x,y,w,h,name,label)
    return "image_button_exit[" ..
        x..","..y..";"..w..","..h..";" ..
        "blockexchange_button_rectangle_depth_border.png;" ..
        name..";"..label..";" ..
        "true;false;" ..
        "blockexchange_button_rectangle_border.png" ..
        "]"
end