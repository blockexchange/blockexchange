function blockexchange.compare_area(pos1, pos2, pos1_load, pos2_load, opts)
    opts = opts or {
        check_param1 = true
    }

    local manip1 = minetest.get_voxel_manip()
	local e1, e2 = manip1:read_from_map(pos1, pos2)
	local area1 = VoxelArea:new({MinEdge=e1, MaxEdge=e2})

    local manip2 = minetest.get_voxel_manip()
    e1, e2 = manip2:read_from_map(pos1_load, pos2_load)
	local area2 = VoxelArea:new({MinEdge=e1, MaxEdge=e2})

    local offset = vector.subtract(pos1_load, pos1)

    local nodeids1 = manip1:get_data()
    local nodeids2 = manip2:get_data()

    local param1_data1 = manip1:get_light_data()
    local param1_data2 = manip2:get_light_data()

    local param2_data1 = manip1:get_param2_data()
    local param2_data2 = manip2:get_param2_data()

	for x=pos1.x,pos2.x do
		for y=pos1.y,pos2.y do
			for z=pos1.z,pos2.z do
                local pos = { x=x, y=y, z=z }
				local i1 = area1:indexp(pos)
                local i2 = area2:indexp(vector.add(pos, offset))

                if nodeids1[i1] ~= nodeids2[i2] then
                    return false, "node-id1: " .. nodeids1[i1] ..
                        " nodename1: " .. minetest.get_name_from_content_id(nodeids1[i1]) ..
                        " node-id2: " .. nodeids2[i2] ..
                        " nodename2: " .. minetest.get_name_from_content_id(nodeids2[i2]) ..
                        " pos: " .. minetest.pos_to_string(pos)
                end
                if opts.check_param1 and param1_data1[i1] ~= param1_data2[i2] then
                    return false, "light, pos: " .. minetest.pos_to_string(pos)
                end
                if param2_data1[i1] ~= param2_data2[i2] then
                    return false, "param2, pos: " .. minetest.pos_to_string(pos)
                end

            end
        end
    end

    return true
end