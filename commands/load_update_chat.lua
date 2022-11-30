minetest.register_chatcommand("bx_load_update", {
    params = "[area_id?]",
    description = "downloads changes",
    func = function(name, area_id)
        local area, err_msg = blockexchange.select_player_area(name, area_id)
        if err_msg then
            return true, err_msg
        end

        local promise, ctx = blockexchange.load(name, area.pos1, area.username, area.name)
        blockexchange.set_job_context(name, ctx)
        promise:next(function()
            blockexchange.set_job_context(ctx.playername, nil)
            minetest.chat_send_player(name, "[blockexchange] Load-update complete")
        end):catch(function(err_msg2)
            blockexchange.set_job_context(ctx.playername, nil)
            minetest.chat_send_player(name, minetest.colorize("#ff0000", err_msg2))
        end)

        return true, "Updating (loading) area: " .. area.id
    end
})