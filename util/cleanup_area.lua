-- nodenames without metadata
local metadata_free_nodenames = {
    ["air"] = true
}

-- nodeid's with zero param2 value
local param2_zero_nodeids = {
    [core.CONTENT_AIR] = true,
    [core.CONTENT_UNKNOWN] = true,
    [core.CONTENT_IGNORE] = true
}

function blockexchange.cleanup_area(pos1, pos2)
    -- load area
    core.load_area(pos1, pos2)

    -- cleanup result
    local result = {
        meta = 0,
        param2 = 0
    }

    -- clear stray metadata
    local pos_list = core.find_nodes_with_meta(pos1, pos2)
    for _, pos in ipairs(pos_list) do
        local node = core.get_node(pos)
        if metadata_free_nodenames[node.name] then
            -- clear metadata
            core.get_meta(pos):from_table(nil)
            result.meta = result.meta + 1
        end
    end

    -- clear invalid param2 values
    local manip = core.get_voxel_manip()
	local e1, e2 = manip:read_from_map(pos1, pos2)
	local area = VoxelArea:new({MinEdge=e1, MaxEdge=e2})

	local node_data = manip:get_data()
	local param2 = manip:get_param2_data()

    local dirty = false
    for x=pos1.x,pos2.x do
    for y=pos1.y,pos2.y do
    for z=pos1.z,pos2.z do
        local i = area:index(x,y,z)
        local nodeid = node_data[i]
        if param2_zero_nodeids[nodeid] and param2[i] ~= 0 then
            -- reset param2 value
            param2[i] = 0
            dirty = true
            result.param2 = result.param2 + 1
        end
    end
    end
    end

    if dirty then
        manip:set_param2_data(param2)
        manip:write_to_map()
        blockexchange.mark_changed(pos1, pos2)
    end

    return result
end