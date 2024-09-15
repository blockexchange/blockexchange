minetest.register_chatcommand("bx_autosave", {
    params = "[area_id?]",
    description = "toggles the autosave feature of the area",
    privs = { blockexchange = true },
    func = function(name, area_id)
        local area, err_msg = blockexchange.select_player_area(name, area_id)
        if err_msg then
            return true, err_msg
        end

        local claims = blockexchange.get_claims(name)
        if not claims or area.username ~= claims.username then
            return true, "You are not authorized to edit that area"
        end

        local msg = "Autosave for area: " .. area.id .. ": "
        if area.autosave then
            area.autosave = false
            msg = msg .. "disabled"
        else
            area.autosave = true
            msg = msg .. "enabled"
        end
        blockexchange.save_areas()
        return true, msg
    end
})