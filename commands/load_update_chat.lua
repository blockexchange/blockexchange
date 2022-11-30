minetest.register_chatcommand("bx_load_update", {
    params = "[area_id?]",
    description = "downloads changes",
    func = function(name, area_id)
        local player = minetest.get_player_by_name(name)
        if not player and not area_id then
            return
        end

        if not area_id or area_id == "" then
            -- use the area_id of the players current position, if available
            local ppos = player:get_pos()
            local area = blockexchange.get_area(ppos)
            if area then
                area_id = area.id
            else
                return true, "No area found at the current position"
            end
        end

        local area = blockexchange.get_area_by_id(area_id)
        if not area then
            return true, "Area '" .. area_id .. "' not found"
        end

        local promise, ctx = blockexchange.load(name, area.pos1, area.username, area.name)
        blockexchange.set_job_context(name, ctx)
        promise:next(function()
            blockexchange.set_job_context(ctx.playername, nil)
            minetest.chat_send_player(name, "[blockexchange] Load-update complete")
        end):catch(function(err_msg)
            blockexchange.set_job_context(ctx.playername, nil)
            minetest.chat_send_player(name, minetest.colorize("#ff0000", err_msg))
        end)

        return true, "Updating (loading) area: " .. area_id
    end
})