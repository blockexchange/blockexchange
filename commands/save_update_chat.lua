minetest.register_chatcommand("bx_save_update", {
    params = "[area_id?]",
    description = "uploads  changes",
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

        local claims = blockexchange.get_claims(name)
        if not claims then
            return true, "Not logged in"
        end

        if claims.username ~= area.username then
            return true, "You are not authorized to update that schema"
        end

        local promise, ctx = blockexchange.save_update(
            name, area.pos1, area.pos1, area.pos2,
            claims.username, area.schema_id
        )
        blockexchange.set_job_context(name, ctx)
        promise:next(function()
            blockexchange.set_job_context(ctx.playername, nil)
            minetest.chat_send_player(name, "[blockexchange] Save-update complete")
        end):catch(function(err_msg)
            blockexchange.set_job_context(ctx.playername, nil)
            minetest.chat_send_player(name, minetest.colorize("#ff0000", err_msg))
        end)
        return true, "Updating area: " .. area_id
    end
})