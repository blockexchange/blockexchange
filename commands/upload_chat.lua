
minetest.register_chatcommand("bx_save", {
  params = "<name> <description>",
	description = "Uploads the selected region to the blockexchange server",
  privs = { blockexchange = true },
	func = function(name, param)
    local has_protected_upload_priv = minetest.check_player_privs(name, { blockexchange_protected_upload = true })
    local has_blockexchange_priv = minetest.check_player_privs(name, { blockexchange = true })

    if not has_blockexchange_priv and not has_protected_upload_priv then
				return false, "Required privs: 'blockexchange' or 'blockexchange_protected_upload'"
		end

    local _, _, schemaname, description = string.find(param, "^([^%s]+)%s+(.*)$")
    if not schemaname or not description then
      return false, "Usage: /bx_save <schemaname> <description>"
    end

    local token = blockexchange.tokens[name]
    if not token then
      -- TODO check validity
      return false, "Please login first to upload a schematic"
    end

    local pos1 = blockexchange.get_pos(1, name)
    local pos2 = blockexchange.get_pos(2, name)

    if not pos1 or not pos2 then
      return false, "you need to set /bx_pos1 and /bx_pos2 first!"
    end

    if not has_blockexchange_priv and has_protected_upload_priv then
      -- kick off protection-check worker and add deferred upload context
      blockexchange.protectioncheck(name, pos1, pos2, schemaname, description)
    else
      -- kick off upload without protect check
      blockexchange.upload(name, pos1, pos2, schemaname, description)
    end

		return true
  end
})
