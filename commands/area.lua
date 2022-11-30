minetest.register_chatcommand("bx_remove_area", {
    params = "[area_id?]",
    description = "removes the area information (not the build)",
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