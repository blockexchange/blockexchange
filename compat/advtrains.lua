-- support for placed tracks in schematics
-- NOTE: there is no support for TCB's, routes or any of that fancy advtrains stuff

assert(type(advtrains.ndb.update) == "function", "ndb update function is present")

minetest.register_on_mods_loaded(function()
    for name, nodedef in pairs(minetest.registered_nodes) do
        if nodedef.groups and nodedef.groups.save_in_at_nodedb then
            local node_id = minetest.get_content_id
            minetest.log("verbose", "[blockexchange] advtrains-support: registering node '" .. name .. "'")
            blockexchange.register_node_deserialize_callback(node_id, advtrains.ndb.update)
        end
    end
end)

