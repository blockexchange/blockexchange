-- placeholder node for foreign unknown nodes

minetest.register_node("blockexchange:placeholder", {
	description = "Blockexchange paceholder node",
	groups = {
    cracky=3,
    oddly_breakable_by_hand=3,
		not_in_creative_inventory=1
  },
	drop = "",
  tiles = {
    "unknown_node.png"
	}
})

-- store the original metadata for later extraction if the node is available then
function blockexchange.placeholder_populate(pos, node_name, metadata)
	local meta = minetest.get_meta(pos)
	local serialized_meta = minetest.serialize(metadata)
	meta:set_string("infotext", "Unknown node: '" .. node_name .. "'")
	meta:set_string("original_nodename", node_name)
	meta:set_string("original_metadata", serialized_meta)
end
