
-- can do *everything*
minetest.register_privilege("blockexchange", {
	description = "can use the blockexchange commands",
	give_to_singleplayer = true
})

-- can do only a subset of the commands
minetest.register_privilege("blockexchange_protected_upload", {
	description = "can use the blockexchange upload command on self-protected areas",
	give_to_singleplayer = false
})
