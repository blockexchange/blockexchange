
function blockexchange.serialize_part(pos1, pos2, node_count)
  local manip = minetest.get_voxel_manip()
  local e1, e2 = manip:read_from_map(pos1, pos2)
  local area = VoxelArea:new({MinEdge=e1, MaxEdge=e2})
  local node_data = manip:get_data()

  local node_id_count = {}
  for x=pos1.x,pos2.x do
  for y=pos1.y,pos2.y do
  for z=pos1.z,pos2.z do
    local i = area:index(x,y,z)
    local node_id = node_data[i]
    local count = node_id_count[node_id] or 0
    node_id_count[node_id] = count + 1
  end
  end
  end

	node_count = node_count or {}
	local node_mapping = {}

	for node_id, count in pairs(node_id_count) do
		local node_name = minetest.get_name_from_content_id(node_id)
		node_mapping[node_name] = node_id
		local counter = node_count[node_name] or 0
		node_count[node_name] = counter + count
	end

	local metadata = {}
	local pos_with_meta = minetest.find_nodes_with_meta(pos1, pos2)
	for _, pos in ipairs(pos_with_meta) do
		local relative_pos = vector.subtract(pos, pos1)
    local meta = minetest.get_meta(pos):to_table()

    -- Convert metadata item stacks to item strings
    for _, invlist in pairs(meta.inventory) do
      for index = 1, #invlist do
        local itemstack = invlist[index]
        if itemstack.to_string then
          invlist[index] = itemstack:to_string()
        end
      end
    end

    metadata[minetest.pos_to_string(relative_pos)] = meta
	end


	local data = {
		node_ids = manip:get_data(),
		param1 = manip:get_light_data(),
		param2 = manip:get_param2_data(),
		node_mapping = node_mapping,
		metadata = metadata,
    size = vector.add( vector.subtract(pos2, pos1), 1 )
	}

  return data, node_count
end

function blockexchange.deserialize_part(pos1, data)
	local pos2 = vector.add(pos1, data.size)

  local manip = minetest.get_voxel_manip()
  local e1, e2 = manip:read_from_map(pos1, pos2)
  local area = VoxelArea:new({MinEdge=e1, MaxEdge=e2})

  -- TODO re-map node-id's

  manip:set_data(data.node_ids)
  manip:set_light_data(data.param1)
  manip:set_param2_data(data.param2)

  -- TODO set metadata

end
