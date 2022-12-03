
local area_store = AreaStore()

-- area_id -> { pos1 = ... }
local area_map

local function create_area_id()
    local template = "xxxxx"
    return string.gsub(template, '[x]', function ()
        return string.format('%x', math.random(0, 0xf))
    end)
end

local function load_areas()
    area_map = minetest.deserialize(blockexchange.mod_storage:get_string("areas_v2")) or {}
    for area_id, persisted_area in pairs(area_map) do
        area_store:insert_area(
            persisted_area.pos1,
            persisted_area.pos2,
            area_id
        )
    end
end

-- load areas on startup
load_areas()

function blockexchange.save_areas()
    blockexchange.mod_storage:set_string("areas_v2", minetest.serialize(area_map))
end

function blockexchange.clear_areas()
    area_map = {}
    blockexchange.save_areas()
end

function blockexchange.register_area(pos1, pos2, username, schema)
    local area_id = create_area_id()
    local data = {
        id = area_id,
        pos1 = pos1,
        pos2 = pos2,
        schema_id = schema.id,
        mtime = schema.mtime,
        name = schema.name,
        username = username,
        sync = "off" -- off,load,save,both
    }
    area_map[area_id] = data
    area_store:insert_area(pos1, pos2, area_id)
    blockexchange.save_areas()
end

function blockexchange.get_area(pos)
    local areas = area_store:get_areas_for_pos(pos, true, true)
    local id = next(areas)
    if id ~= nil then
        local area = areas[id]
        return area_map[area.data]
    end
end

function blockexchange.remove_area(area_id)
    area_map[area_id] = nil
    blockexchange.save_areas()
end

function blockexchange.get_area_by_id(area_id)
    return area_map[area_id]
end
