-- placeholder node for foreign unknown nodes

minetest.register_node("blockexchange:placeholder", {
	description = "Blockexchange paceholder node",
	groups = {
    cracky=3,
    oddly_breakable_by_hand=3,
		not_in_creative_inventory=1
  },
  tiles = {
    "unknown_node.png"
	}
})
