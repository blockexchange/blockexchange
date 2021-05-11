
minetest.register_chatcommand("bx_save", {
  params = "<name>",
	description = "Uploads the selected region to the blockexchange server",
	func = blockexchange.api_check_wrapper(function(name, schemaname)
    local has_protected_upload_priv = minetest.check_player_privs(name, { blockexchange_protected_upload = true })
		local has_blockexchange_priv = minetest.check_player_privs(name, { blockexchange = true })
		local has_protection_bypass_priv = minetest.check_player_privs(name, { protection_bypass = true })

    if not has_blockexchange_priv and not has_protected_upload_priv then
				return true, "Required privs: 'blockexchange' or 'blockexchange_protected_upload'"
		end

    if not schemaname then
      return true, "Usage: /bx_save <schemaname>"
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

    if not has_blockexchange_priv and has_protected_upload_priv and not has_protection_bypass_priv then
      -- kick off protection-check worker and add deferred upload context
      blockexchange.protectioncheck(name, pos1, pos2, schemaname)
    else
      -- kick off upload without protect check
      blockexchange.save(name, pos1, pos2, schemaname)
    end

		return true
  end)
})
