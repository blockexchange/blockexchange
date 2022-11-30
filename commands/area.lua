minetest.register_chatcommand("bx_remove_area", {
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

        blockexchange.remove_area(area_id)
        return true, "Area '" .. area_id .. "' removed"
    end
})