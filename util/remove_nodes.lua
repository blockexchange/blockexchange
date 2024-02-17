local air_cid = minetest.get_content_id("air")

function blockexchange.remove_nodes(pos1, pos2)
    local manip = minetest.get_voxel_manip()
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
    local nodes_with_meta = minetest.find_nodes_with_meta(pos1, pos2)
    for _, pos in ipairs(nodes_with_meta) do
        local meta = minetest.get_meta(pos)
        meta:from_table({})
    end

    -- remove areas
    local list = blockexchange.get_areas_in_area(pos1, pos2)
    for _, a in ipairs(list) do
        blockexchange.remove_area(a.id)
    end
end