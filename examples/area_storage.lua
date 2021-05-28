-- luacheck: no unused

local pos1 = { x=1, y=0, z=0 }
local data = blockexchange.get_area(pos1)

-- upload example data
data = {
    pos1 = { x=0, y=0, z=0 },
    pos2 = { x=2, y=0, z=0 },
    data = {
        type = "upload",
        schemaid = 99,
        schemaname = "my_schema",
        username = "MyAccount",
        owner = "singleplayer",
        origin = { x=0, y=0, z=0 }
    }
}

-- download example data
data = {
    pos1 = { x=0, y=0, z=0 },
    pos2 = { x=2, y=0, z=0 },
    data = {
        type = "download",
        schemaid = 99,
        schemaname = "my_schema",
        username = "MyAccount",
        owner = "singleplayer",
        origin = { x=0, y=0, z=0 }
    }
}

