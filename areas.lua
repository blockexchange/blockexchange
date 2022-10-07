
local area_store = AreaStore()
local area_list
local next_id = 1

local function get_next_id()
    next_id = next_id + 1
    return next_id - 1
end

local function load_areas()
    area_list = minetest.deserialize(blockexchange.mod_storage:get_string("areas")) or {}
    for _, persisted_area in ipairs(area_list) do
        persisted_area.id = get_next_id()
        area_store:insert_area(
            persisted_area.pos1,
            persisted_area.pos2,
            minetest.serialize(persisted_area),
            persisted_area.id
        )
    end
end

-- load areas on startup
load_areas()

local function save_areas()
    blockexchange.mod_storage:set_string("areas", minetest.serialize(area_list))
end

function blockexchange.register_area(pos1, pos2, username, schema)
    local data = {
        id = get_next_id(),
        pos1 = pos1,
        pos2 = pos2,
        schema_id = schema.id,
        mtime = schema.mtime,
        name = schema.name,
        username = username,
        sync = "off" -- off,pull,push,both
    }
    table.insert(area_list, data)
    area_store:insert_area(pos1, pos2, minetest.serialize(data), data.id)
    save_areas()
end

function blockexchange.get_area(pos)
    local areas = area_store:get_areas_for_pos(pos, true, true)
    local id = next(areas)
    if id ~= nil then
        return area_list[id]
    end
end

