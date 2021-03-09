local placeholder_id = minetest.get_content_id("blockexchange:placeholder")

-- local nodename->id cache
local local_nodename_to_id_mapping = {} -- name -> id
local next_unknown_nodeid = -1
local unknown_nodes_id_to_name_mapping = {}

function blockexchange.deserialize_part(pos1, pos2, data)
	local foreign_nodeid_to_name_mapping = {} -- id -> name
	for k, v in pairs(data.node_mapping) do
		foreign_nodeid_to_name_mapping[v] = k
	end

	local node_names = {}

	local manip = minetest.get_voxel_manip()
	local e1, e2 = manip:read_from_map(pos1, pos2)
	local area = VoxelArea:new({MinEdge=e1, MaxEdge=e2})

	for i, node_id in ipairs(data.node_ids) do
		local node_name = foreign_nodeid_to_name_mapping[node_id]
		node_names[node_name] = true

		local local_node_id = local_nodename_to_id_mapping[node_name]
		if not local_node_id then
			if minetest.registered_nodes[node_name] then
				-- node is locally available
				local_node_id = minetest.get_content_id(node_name)
			else
				-- node is not available here, give out negative nodeids
				local_node_id = next_unknown_nodeid
				unknown_nodes_id_to_name_mapping[local_node_id] = node_name
				next_unknown_nodeid = next_unknown_nodeid - 1
			end
			local_nodename_to_id_mapping[node_name] = local_node_id

		end

		data.node_ids[i] = local_node_id
	end

	local node_data = manip:get_data()
	local param1 = manip:get_light_data()
	local param2 = manip:get_param2_data()

	local placeholder_pos_hashes = {}

	local j = 1
	for x=pos1.x,pos2.x do
		for y=pos1.y,pos2.y do
			for z=pos1.z,pos2.z do
				local i = area:index(x,y,z)
				if data.node_ids[j] < 0 then
					-- unknown node, set placeholder
					node_data[i] = placeholder_id
					-- mark node for later
					local hash = minetest.hash_node_position({x=x, y=y, z=z})
					placeholder_pos_hashes[hash] = data.node_ids[j]
				else
					node_data[i] = data.node_ids[j]
				end

				-- place param1 and param2 regardless of known/unknown node
				param1[i] = data.param1[j]
				param2[i] = data.param2[j]
				j = j + 1
			end
		end
	end

	manip:set_data(node_data)
	manip:set_light_data(param1)
	manip:set_param2_data(param2)
	manip:write_to_map()

	-- deserialize metadata
	if data.metadata and data.metadata.meta then
		for pos_str, metadata in pairs(data.metadata.meta) do
			local relative_pos = minetest.string_to_pos(pos_str)
			local absolute_pos = vector.add(pos1, relative_pos)
			local hash = minetest.hash_node_position(absolute_pos)
			local unknown_node_id = placeholder_pos_hashes[hash]
			if unknown_node_id then
				-- extract node name
				local node_name = unknown_nodes_id_to_name_mapping[unknown_node_id]
				-- populate proper placeholder node with metadata
				blockexchange.placeholder_populate(absolute_pos, node_name, metadata)
				-- remove from placeholder hashes
				placeholder_pos_hashes[hash] = nil
			else
				-- plain metadata of a known node
				minetest.get_meta(absolute_pos):from_table(metadata)
			end
		end
	end

	-- go over all non-replaced unknown nodes
	for hash, nodeid in pairs(placeholder_pos_hashes) do
		local node_name = unknown_nodes_id_to_name_mapping[nodeid]
		local pos = minetest.get_position_from_hash(hash)
		blockexchange.placeholder_populate(pos, node_name)
	end

	-- deserialize node timers
	if data.metadata and data.metadata.timers then
		for pos_str, timer_data in pairs(data.metadata.timers) do
			local relative_pos = minetest.string_to_pos(pos_str)
			local absolute_pos = vector.add(pos1, relative_pos)
			minetest.get_node_timer(absolute_pos):set(timer_data.timeout, timer_data.elapsed)
		end
	end

	return node_names
end
