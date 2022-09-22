local SCHEMS_DIR = minetest.get_worldpath() .. "/bxschems"
minetest.mkdir(SCHEMS_DIR)

function blockexchange.get_local_filename(name)
    return SCHEMS_DIR .. "/" .. name .. ".zip"
end
