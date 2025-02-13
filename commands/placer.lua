if not minetest.get_modpath("wield_events") then
    -- wield-events not available
    return
end

local max_size = 100

local function create_placer_tool(username, schemaname, schema)
    local size = {
        x = schema.size_x,
        y = schema.size_y,
        z = schema.size_z
    }

    local tool = ItemStack("blockexchange:place 1")
    local tool_meta = tool:get_meta()
    tool_meta:set_string("size", minetest.pos_to_string(size))
    tool_meta:set_string("username", username)
    tool_meta:set_string("schemaname", schemaname)

    local desc = string.format(
        "Placement tool for %s/%s, size: %s nodes",
        username, schemaname, minetest.pos_to_string(size)
    )
    tool_meta:set_string("description", desc)

    return tool
end

minetest.register_chatcommand("bx_placer", {
    params = "<username> <schemaname>",
    description = "Creates a placement tool for the schematic",
    privs = {blockexchange = true},
    func = function(name, param)
        local _, _, username, schemaname = string.find(param, "^([^%s]+)%s+(.*)$")
        if not username or not schemaname then
            return false, "Usage: /bx_placer <username> <schemaname>"
        end

        blockexchange.api.get_schema_by_name(username, schemaname, true):next(function(schema)
            if schema.size_x > max_size or
                schema.size_y > max_size or
                schema.size_z > max_size then
                    minetest.chat_send_player(name, "Max-axis size of 100 nodes exceeded!")
                    return
            end

            local tool = create_placer_tool(username, schemaname, schema)
            local player = minetest.get_player_by_name(name)
            if not player then
                -- player not found
                minetest.chat_send_player(name, "Player not found!")
                return
            end

            local inv = player:get_inventory()
            if inv:room_for_item("main", tool) then
                inv:add_item("main", tool)
                minetest.chat_send_player(name, "Placement tool added to inventory")
            else
                minetest.chat_send_player(name, "Inventory is full!")
            end
        end):catch(function(err)
            minetest.chat_send_player(name, "Loading schematic metadata failed: " .. (err or "<unknown error>"))
        end)

        return true
    end
})
