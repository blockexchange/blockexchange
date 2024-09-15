
minetest.register_chatcommand("bx_save", {
  params = "<name>",
  description = "Uploads the selected region to the blockexchange server",
  func = blockexchange.api_check_wrapper(function(name, schemaname)
    -- force-enable the hud
    blockexchange.set_player_hud(name, true)

    if blockexchange.get_job_context(name) then
      return true, "There is a job already running"
    end

    local has_protected_upload_priv = minetest.check_player_privs(name, { blockexchange_protected_upload = true })
    local has_blockexchange_priv = minetest.check_player_privs(name, { blockexchange = true })
    local has_protection_bypass_priv = minetest.check_player_privs(name, { protection_bypass = true })

    if not has_blockexchange_priv and not has_protected_upload_priv then
      return true, "Required privs: 'blockexchange' or 'blockexchange_protected_upload'"
    end

    if not schemaname then
      return true, "Usage: /bx_save <schemaname>"
    end

    if not blockexchange.validate_name(schemaname) then
      return true, "schema name can only contain letters, numbers and a handful of special chars: - _ ."
    end

    local token = blockexchange.get_token(name)
    if not token then
      -- TODO check validity
      return true, "Please login first to upload a schematic"
    end

    local pos1 = blockexchange.get_pos(1, name)
    local pos2 = blockexchange.get_pos(2, name)

    if not pos1 or not pos2 then
      return true, "you need to set /bx_pos1 and /bx_pos2 first!"
    end

    if not blockexchange.check_size(pos1, pos2) then
      return true, "axis size limit of " .. blockexchange.max_size .. " nodes exceeded"
    end

    -- force-enable player-hud
    blockexchange.set_player_hud(name, true)

    if not has_blockexchange_priv and has_protected_upload_priv and not has_protection_bypass_priv then
      -- kick off protection-check worker and add deferred upload context
      local promise, ctx = blockexchange.protectioncheck(name, pos1, pos2, schemaname)
      blockexchange.set_job_context(name, ctx)
      promise:next(function(result)
        if not result.success then
          blockexchange.set_job_context(ctx.playername, nil)
          local msg = "Protection check failed between pos " .. minetest.pos_to_string(result.pos1) ..
            " and " .. minetest.pos_to_string(result.pos2)
          minetest.chat_send_player(name, minetest.colorize("#ff0000", msg))
          return
        end
        -- kick off save process
        promise, ctx = blockexchange.save(name, pos1, pos2, schemaname)
        blockexchange.set_job_context(name, ctx)
        return promise
      end):next(function(result)
        blockexchange.set_job_context(ctx.playername, nil)
        minetest.chat_send_player(name, "[blockexchange] Save complete with " .. result.total_parts .. " parts")
      end):catch(function(err_msg)
        blockexchange.set_job_context(ctx.playername, nil)
        minetest.chat_send_player(name, minetest.colorize("#ff0000", err_msg))
      end)
    else
      -- kick off upload directly without protect check
      local promise, ctx = blockexchange.save(name, pos1, pos2, schemaname)
      blockexchange.set_job_context(name, ctx)
      promise:next(function(result)
        blockexchange.set_job_context(ctx.playername, nil)
        minetest.chat_send_player(name, "[blockexchange] Save complete with " .. result.total_parts .. " parts")
      end):catch(function(err_msg)
        blockexchange.set_job_context(ctx.playername, nil)
        minetest.chat_send_player(name, minetest.colorize("#ff0000", err_msg))
      end)
    end

    return true
  end)
})
