local SCHEMS_DIR = core.get_worldpath() .. "/bxschems"
core.mkdir(SCHEMS_DIR)

function blockexchange.get_local_filename(name)
    return SCHEMS_DIR .. "/" .. name .. ".zip"
end
