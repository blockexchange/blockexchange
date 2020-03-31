
function blockexchange.serialize_part(pos, end_pos, node_count)
  local pos2 = vector.add(pos, blockexchange.part_length)
  pos2.x = math.min(pos2.x, end_pos.x)
  pos2.y = math.min(pos2.y, end_pos.y)
  pos2.z = math.min(pos2.z, end_pos.z)

  local manip = minetest.get_voxel_manip()
  local e1, e2 = manip:read_from_map(pos, pos2)
  local area = VoxelArea:new({MinEdge=e1, MaxEdge=e2})
  local node_data = manip:get_data()

  local node_id_count = {}
  for x=pos.x,pos2.x do
  for y=pos.y,pos2.y do
  for z=pos.z,pos2.z do
    local i = area:index(x,y,z)
    local node_id = node_data[i]
    local count = node_id_count[node_id] or 0
    node_id_count[node_id] = count + 1
  end
  end
  end

	node_count = node_count or {}

	for node_id, count in pairs(node_id_count) do
		local node_name = minetest.get_name_from_content_id(node_id)
		local counter = node_count[node_name] or 0
		node_count[node_name] = counter + count
	end

  return worldedit.serialize(pos, pos2), node_count
end

function blockexchange.deserialize_part(pos, data)
	worldedit.deserialize(pos, data)
end
