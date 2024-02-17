minetest.register_chatcommand("bx_load_update", {
    params = "[area_id?]",
    description = "downloads changes",
    func = function(name, area_id)
        local area, err_msg = blockexchange.select_player_area(name, area_id)
        if err_msg then
            return false, err_msg
        end

        blockexchange.api.get_schema_by_uid(area.schema_uid):next(function(remote_schema)
            if not remote_schema then
                return Promise.rejected("schema not found: " .. areas.schema_uid)
            end
            local remote_size = blockexchange.get_schema_size(remote_schema)
            local local_size = vector.subtract(area.pos2, area.pos1)

            if not vector.equals(local_size, remote_size) then
                minetest.chat_send_player(name, minetest.colorize("#ff0000", "Remote schema-size changed"))
                return
            end

            minetest.chat_send_player(name, "Updating (loading) area: " .. area.id)

            local promise, ctx = blockexchange.load(name, area.pos1, area.username, area.name, false, area.mtime)
            blockexchange.set_job_context(name, ctx)
            return promise:next(function(stat)
                -- clear job
                blockexchange.set_job_context(name, nil)

                if stat.last_schemapart then
                    -- some parts have been updated
                    -- save last mtime
                    area.mtime = stat.last_schemapart.mtime
                    blockexchange.save_areas()
                    minetest.chat_send_player(
                        name,
                        "[blockexchange] Load-update complete with " .. ctx.total_parts .. " parts"
                    )
                else
                    -- nothing has been updated
                    minetest.chat_send_player(name, "[blockexchange] No updates available")
                end
            end)
        end):catch(function(err_msg2)
            blockexchange.set_job_context(name, nil)
            minetest.chat_send_player(name, minetest.colorize("#ff0000", err_msg2))
        end)
    end
})