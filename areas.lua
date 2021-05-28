---------
-- area management

local FILENAME = minetest.get_worldpath() .. "/bx_areas.json"
local store = AreaStore()
local cache = {}

local function save_areas()
    local list = {}
    for _, entry in pairs(cache) do
        table.insert(list, entry)
    end

    local file = io.open(FILENAME,"w")
	local json = minetest.write_json(list)
	if file and file:write(json) and file:close() then
		return
	else
		error("write to '" .. FILENAME .. "' failed!")
	end
end

local function load_areas()
    local file = io.open(FILENAME,"r")
    if not file then
        return
    end

    local json = file:read("*a")
    local list = minetest.parse_json(json)
    if not list then
        return
    end

    for _, entry in ipairs(list) do
        local id = store:insert_area(entry.pos1, entry.pos2, "")
        cache[id] = entry
    end
end

minetest.after(0, load_areas)

--- registers an area
-- @param pos1 the lower position
-- @param pos2 the upper position
-- @param data the data to save with
-- @see area_storage.lua
function blockexchange.register_area(pos1, pos2, data)
    local id = store:insert_area(pos1, pos2, "")
    cache[id] = {
        pos1 = pos1,
        pos2 = pos2,
        data = data
    }
    save_areas()
end

--- returns the first found area in that region
-- @param pos1 the lower position
-- @param pos2 the upper position
-- @return the area data
-- @see area_storage.lua
function blockexchange.get_area(pos1, pos2)
    local list = store:get_areas_in_area(pos1, pos2, true, false)
    if not list then
        return
    else
        -- return first result
        local id = next(list)
        return cache[id]
    end
end