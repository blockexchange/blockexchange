minetest.register_chatcommand("bx_area_remove", {
    params = "[area_id?]",
    description = "removes the area information (not the build)",
    func = function(name, area_id)
        local area, err_msg = blockexchange.select_player_area(name, area_id)
        if err_msg then
            return true, err_msg
        end

        local is_admin = minetest.check_player_privs(name, "blockexchange")

        if not is_admin then
            -- check login info, if available
            local claims = blockexchange.get_claims(name)
            if not claims then
                return true, "Not logged in"
            end

            if claims.username ~= area.username then
                return true, "You are not authorized to remove that area"
            end
        end

        blockexchange.remove_area(area.id)
        return true, "Area '" .. area.id .. "' removed"
    end
})

minetest.register_chatcommand("bx_area_mark", {
    params = "[area_id?]",
    description = "marks the area",
    privs = { worldedit = true },
    func = function(name, area_id)
        local area, err_msg = blockexchange.select_player_area(name, area_id)
        if err_msg then
            return true, err_msg
        end

        local player = minetest.get_player_by_name(name)
        if player then
            blockexchange.set_pos(1, name, area.pos1)
            blockexchange.set_pos(2, name, area.pos2)
        end

        return true, "Area '" .. area.id .. "' marked"
    end
})