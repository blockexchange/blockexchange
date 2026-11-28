---------
-- stubs for the removed area-tracking commands, they point to the /bx_sync replacement
-- TODO: remove in the next release

local replacements = {
	bx_save_update = "/bx_sync push",
	bx_load_update = "/bx_sync pull",
	bx_autosave = "/bx_sync autosave <on|off>",
	bx_area_remove = "/bx_sync unlink",
	bx_area_mark = "the 'Mark region' button in /bx_sync"
}

for name, replacement in pairs(replacements) do
	core.register_chatcommand(name, {
		description = "Removed, use " .. replacement .. " instead",
		func = function()
			return true, core.colorize("#ffff00", "/" .. name .. " has been removed, use " .. replacement ..
				" instead (previously tracked areas are migrated to synced regions, see /bx_sync)")
		end
	})
end
