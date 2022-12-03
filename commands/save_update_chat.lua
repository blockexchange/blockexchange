minetest.register_chatcommand("bx_save_update", {
    params = "[area_id?]",
    description = "uploads changes",
    func = function(name, area_id)
        local area, err_msg = blockexchange.select_player_area(name, area_id)
        if err_msg then
            return true, err_msg
        end

        local claims = blockexchange.get_claims(name)
        if not claims then
            return true, "Not logged in"
        end

        if claims.username ~= area.username then
            return true, "You are not authorized to update that schema"
        end

        local promise, ctx

        local pos1 = blockexchange.get_pos(1, name)
        local pos2 = blockexchange.get_pos(2, name)

        if pos1 and pos2 then
            -- partial update with the marked area
            pos1, pos2 = blockexchange.sort_pos(pos1, pos2)
            promise, ctx = blockexchange.save_update_area(
                name, area.pos1, area.pos2, pos1, pos2,
                claims.username, area.schema_id
            )
        else
            -- update _everything_
            promise, ctx = blockexchange.save_update(
                name, area.pos1, area.pos1, area.pos2,
                claims.username, area.schema_id
            )
        end

        blockexchange.set_job_context(name, ctx)
        promise:next(function()
            blockexchange.set_job_context(ctx.playername, nil)
            minetest.chat_send_player(name, "[blockexchange] Save-update complete")
        end):catch(function(err_msg2)
            blockexchange.set_job_context(ctx.playername, nil)
            minetest.chat_send_player(name, minetest.colorize("#ff0000", err_msg2))
        end)
        return true, "Updating (saving) area: " .. area.id
    end
})