local air_cid = core.get_content_id("air")

function blockexchange.remove_nodes(pos1, pos2)
    local manip = core.get_voxel_manip()
	local e1, e2 = manip:read_from_map(pos1, pos2)
	local area = VoxelArea:new({MinEdge=e1, MaxEdge=e2})

    local node_data = manip:get_data()
    local param2 = manip:get_param2_data()

    for z=pos1.z,pos2.z do
    for x=pos1.x,pos2.x do
    for y=pos1.y,pos2.y do
        local i = area:index(x,y,z)
        node_data[i] = air_cid
        param2[i] = 0
    end
    end
    end

    manip:set_data(node_data)
    manip:set_param2_data(param2)
    manip:write_to_map()

    -- clear metadata
    local nodes_with_meta = core.find_nodes_with_meta(pos1, pos2)
    for _, pos in ipairs(nodes_with_meta) do
        local meta = core.get_meta(pos)
        meta:from_table({})
    end

    -- unlink synced regions inside the removed area, mark the changes of partially removed regions
    pos1, pos2 = blockexchange.sort_pos(pos1, pos2)
    for _, entry in ipairs(blockexchange.sync.get_in_area(pos1, pos2)) do
        local inside = entry.pos1.x >= pos1.x and entry.pos1.y >= pos1.y and entry.pos1.z >= pos1.z and
            entry.pos2.x <= pos2.x and entry.pos2.y <= pos2.y and entry.pos2.z <= pos2.z
        if inside then
            blockexchange.sync.remove(entry.id)
        else
            blockexchange.mark_changed(pos1, pos2)
        end
    end
end