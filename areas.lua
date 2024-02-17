local has_mapsync = minetest.get_modpath("mapsync")
local area_storage_key = "areas_v3"

local area_store

-- area_id -> { pos1 = ... }
local area_map

local function create_area_id()
    local template = "xxxxx"
    return string.gsub(template, '[x]', function ()
        return string.format('%x', math.random(0, 0xf))
    end)
end

function blockexchange.load_areas()
    area_store = AreaStore()
    if has_mapsync then
        -- try loading mapsync persisted bx-areas
        area_map = mapsync.load_data("bx_areas")
    end

    if not area_map then
        -- load bx-areas from mod-storage or create an empty table
        local json = blockexchange.mod_storage:get_string(area_storage_key)
        if not json or json == "" then
            json = "{}"
        end
        area_map = minetest.parse_json(json) or {}
    end
    for area_id, persisted_area in pairs(area_map) do
        area_store:insert_area(
            persisted_area.pos1,
            persisted_area.pos2,
            area_id
        )
    end
end

-- load areas after all mods are loaded
minetest.register_on_mods_loaded(blockexchange.load_areas)

function blockexchange.save_areas()
    -- save to mod-storage
    blockexchange.mod_storage:set_string(area_storage_key, minetest.write_json(area_map))

    if has_mapsync then
        -- persist to mapsync too
        mapsync.save_data("bx_areas", area_map)
    end
end

function blockexchange.clear_areas()
    area_map = {}
    blockexchange.save_areas()
end

function blockexchange.register_area(pos1, pos2, playername, username, schema)
    local area_id = create_area_id()
    local data = {
        id = area_id,
        pos1 = pos1,
        pos2 = pos2,
        schema_uid = schema.uid,
        mtime = schema.mtime,
        name = schema.name,
        username = username,
        playername = playername,
        autosave = false,
        autoload = false
    }
    area_map[area_id] = data
    area_store:insert_area(pos1, pos2, area_id)
    blockexchange.save_areas()
end

function blockexchange.get_areas_in_area(pos1, pos2)
    local areas = area_store:get_areas_in_area(pos1, pos2, true, true, true)
    local list = {}
    for _, area in pairs(areas) do
        if area_map[area.data] then
            table.insert(list, area_map[area.data])
        end
    end
    return list
end

function blockexchange.get_area(pos)
    local areas = area_store:get_areas_for_pos(pos, true, true)
    for id, area in pairs(areas) do
        if area_map[area.data] then
            -- return
            return area_map[area.data]
        else
            -- cleanup
            area_store:remove_area(id)
        end
    end
end

function blockexchange.remove_area(area_id)
    area_map[area_id] = nil
    blockexchange.save_areas()
end

function blockexchange.get_area_by_id(area_id)
    return area_map[area_id]
end
