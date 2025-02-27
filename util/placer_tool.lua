if not minetest.get_modpath("wield_events") then
    -- wield-events not available
    return
end

minetest.register_tool("blockexchange:place", {
    description = "Placement tool",
    inventory_image = "blockexchange_plus.png^[colorize:#0000ff",
    stack_max = 1,
    range = 0,
    groups = {
        not_in_creative_inventory = 1
    },
    on_use = function(itemstack, player)
        local playername = player:get_player_name()
        local controls = player:get_player_control()

        local meta = itemstack:get_meta()
        local username = meta:get_string("username")
        local schemaname = meta:get_string("schemaname")
        local size = minetest.string_to_pos(meta:get_string("size"))
        local distance = vector.distance(vector.new(), size)

        local pos1 = blockexchange.get_pointed_position(player, math.max(10, distance) + 5)
        local pos2 = vector.add(pos1, vector.subtract(size, 1))

        if controls.aux1 then
            -- removal
            blockexchange.remove_nodes(pos1, pos2)
        else
            -- placement
            -- force-enable player-hud
            blockexchange.set_player_hud(playername, true)

            blockexchange.load(playername, pos1, username, schemaname):next(function(result)
                minetest.chat_send_player(
                    playername,
                    "Download complete with " .. result.schema.total_parts .. " parts"
                )
            end):catch(function(err_msg)
                minetest.chat_send_player(playername, minetest.colorize("#ff0000", err_msg))
            end)
        end
    end,
    on_step = function(itemstack, player)
        local playername = player:get_player_name()
        local controls = player:get_player_control()

        local meta = itemstack:get_meta()
        local size = minetest.string_to_pos(meta:get_string("size"))
        local distance = vector.distance(vector.new(), size)

        local pos1 = blockexchange.get_pointed_position(player, math.max(10, distance) + 5)
        local pos2 = vector.add(pos1, vector.subtract(size, 1))

        if controls.aux1 then
            -- removal preview
            blockexchange.show_preview(playername, "blockexchange_minus.png", "#ff0000", pos1, pos2)
        else
            -- build preview
            blockexchange.show_preview(playername, "blockexchange_plus.png", "#0000ff", pos1, pos2)
        end
    end,
    on_deselect = function(_, player)
        local playername = player:get_player_name()
        blockexchange.clear_preview(playername)
    end
})
