minetest.register_chatcommand("blockexchange_save", {
  params = "",
	description = "",
	func = function(name)
    local pos1 = worldedit.pos1[name]
    local pos2 = worldedit.pos2[name]
		local description = ""
		local tags = {}

    blockexchange.upload(pos1, pos2, description, tags)
  end
})

minetest.register_chatcommand("blockexchange_load", {
  params = "<schemaid>",
	description = "",
	func = function(name, param)
    local pos1 = worldedit.pos1[name]
		blockexchange.download(pos1, param)
  end
})
