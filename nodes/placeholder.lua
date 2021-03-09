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


minetest.register_lbm({
	label = "restore unknown nodes",
	name = "blockexchange:restore_unknown_nodes",
	nodenames = {"blockexchange:blockexchange"},
	run_at_every_load = true,
	action = function(pos)
		local meta = minetest.get_meta(pos)
		local nodename = meta:get_string("original_nodename")
		if minetest.registered_nodes[nodename] then
			-- node exists now, restore it
			minetest.swap_node(pos, { name=nodename })
			local serialized_meta = meta:get_string("original_metadata")
			if serialized_meta ~= "" then
				-- restore metadata and inventory
				local metadata = minetest.deserialize(serialized_meta)
				meta:from_table(metadata)
			end
		end
	end
})
