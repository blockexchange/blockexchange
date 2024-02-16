minetest.register_chatcommand("bx_save_update", {
    params = "[area_id?]",
    description = "uploads selected changes or the whole area",
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

        local pos1 = blockexchange.get_pos(1, name)
        local pos2 = blockexchange.get_pos(2, name)

        if not pos1 or not pos2 then
            -- upload everything
            pos1 = area.pos1
            pos2 = area.pos2
        end

        -- partial update with the marked area
        pos1, pos2 = blockexchange.sort_pos(pos1, pos2)
        local promise, ctx = blockexchange.save_update_area(
            name, area.pos1, area.pos2, pos1, pos2, claims.username, area.schema_uid
        )

        blockexchange.set_job_context(name, ctx)
        promise:next(function()
            -- fetch updated schema
            return blockexchange.api.get_schema_by_uid(area.schema_uid)
        end):next(function(schema)
            if not schema then
                return Promise.rejected("schema not found: " .. areas.schema_uid)
            end
            -- update mtime in local area
            area.mtime = schema.mtime
            blockexchange.save_areas()
            blockexchange.set_job_context(ctx.playername, nil)
            minetest.chat_send_player(name, "[blockexchange] Save-update complete with " .. ctx.total_parts .. " parts")
        end):catch(function(err_msg2)
            blockexchange.set_job_context(ctx.playername, nil)
            minetest.chat_send_player(name, minetest.colorize("#ff0000", err_msg2))
        end)
        return true, "Updating (saving) area: " .. area.id
    end
})