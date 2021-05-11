local SCHEMS_DIR = minetest.get_worldpath() .. "/bxschems"
minetest.mkdir(SCHEMS_DIR)

local function get_schema_dir(name)
    local dir = SCHEMS_DIR .. "/" .. name
    minetest.mkdir(dir)
    return dir
end

local function save_json(filename, data)
    local file = io.open(filename, "w")
    local json = minetest.write_json(data)
    if file and file:write(json) and file:close() then
        return
    else
        minetest.log("error", "[blockexchange] persist failed for '" .. filename .. "'")
        return
    end
end

local function load_json(filename)
    local file = io.open(filename, "r")

    if file then
        local json = file:read("*a")
        if not json or json == "" then return end
        return minetest.parse_json(json)
    end
end

function blockexchange.create_local_schema(pos1, pos2, license, name)
    local data = {
        size_x = pos2.x - pos1.x + 1,
        size_y = pos2.y - pos1.y + 1,
        size_z = pos2.z - pos1.z + 1,
        part_length = blockexchange.part_length,
        license = license,
        name = name
    };

    save_json(get_schema_dir(name) .. "/schema.json", data)
end

function blockexchange.create_local_schemapart(name, schemapart)
    save_json(get_schema_dir(name) .. "/schemapart_" .. schemapart.offset_x ..
                  "_" .. schemapart.offset_y .. "_" .. schemapart.offset_z ..
                  ".json", schemapart)
end

function blockexchange.create_local_schemamods(name, mod_names)
    save_json(get_schema_dir(name) .. "/mods.json", mod_names)
end

function blockexchange.get_local_schema(name)
    return load_json(get_schema_dir(name) .. "/schema.json")
end

function blockexchange.get_local_schemapart(name, x, y, z)
    return load_json(get_schema_dir(name) .. "/schemapart_" .. x .. "_" .. y .. "_" .. z .. ".json")
end

function blockexchange.get_local_schemamods(name)
    return load_json(get_schema_dir(name) .. "/mods.json")
end