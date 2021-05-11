
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

load_areas()

function blockexchange.register_area(pos1, pos2, data)
    local id = store:insert_area(pos1, pos2, "")
    cache[id] = {
        pos1 = pos1,
        pos2 = pos2,
        data = data
    }
    save_areas()
end

function blockexchange.get_area_at_pos(pos)
    local list = store:get_areas_for_pos(pos, true, false)
    for id, entry in pairs(list) do
        print(id, dump(entry))
    end
end

--[[
minetest.register_chatcommand("bx_test", {
    func = function(name)
        local player = minetest.get_player_by_name(name)
        local pos = player:get_pos()
        blockexchange.get_area_at_pos(pos)
    end
})
--]]