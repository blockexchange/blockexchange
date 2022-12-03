minetest.register_chatcommand("bx_load_local", {
    params = "<schemaname>",
    description = "loads a local schema to the selected pos1",
    privs = {blockexchange = true},
    func = function(name, schemaname)
        if blockexchange.get_job_context(name) then
            return true, "There is a job already running"
        end

        if not schemaname or schemaname == "" then
            return false, "Usage: /bx_load <username> <schemaname>"
        end

        local pos1 = blockexchange.get_pos(1, name)

        if not pos1 then return false, "you need to set /bx_pos1 first!" end

        local promise, ctx = blockexchange.load(name, pos1, name, schemaname, true)
        blockexchange.set_job_context(name, ctx)

        promise:next(function()
            minetest.chat_send_player(name, "Download complete with " .. ctx.total_parts .. " parts")
            blockexchange.set_job_context(name, nil)
        end):catch(function(err_msg)
            minetest.chat_send_player(name, minetest.colorize("#ff0000", err_msg))
            blockexchange.set_job_context(name, nil)
        end)
        return true
    end
})

