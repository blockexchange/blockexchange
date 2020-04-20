
minetest.register_node("blockexchange:controller", {
	description = "Blockexchange controller",
	tiles = {
		"blockexchange_controller.png"
	},
	groups = {
		cracky=3,
		oddly_breakable_by_hand=3
	}
})

--[[

UI:
 * extends -x -y -z / +x +y +z
 * Name
 * Username (prefilled on "Upload")

Features:
 * Upload: uploads the region with the specified schema name
 * Upload-Overwrite: uploads again and replaces the previous schema
 * Download: downloads/updates/restores from remote
 * Check: check if the remote schema is newer

On upload:
 * Save owner to controller-metadata *before* uploading
 * Save schema timestamp to controller-metadata *before* uploading

On download:
 * Check size, if not equal: abort

--]]
