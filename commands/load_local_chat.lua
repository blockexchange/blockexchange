minetest.register_chatcommand("bx_load_local", {
    params = "<schemaname>",
    description = "loads a local schema to the selected pos1",
    privs = {blockexchange = true},
    func = function(name, schemaname)
        if not schemaname or schemaname == "" then
            return false, "Usage: /bx_load <username> <schemaname>"
        end

        local pos1 = blockexchange.get_pos(1, name)

        if not pos1 then return false, "you need to set /bx_pos1 first!" end

        blockexchange.load(name, pos1, name, schemaname, true)
        return true
    end
})

