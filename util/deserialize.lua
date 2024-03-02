---------
-- deserialization functions

local string_byte, math_floor, hash_node_position = string.byte, math.floor, minetest.hash_node_position
local table_insert = table.insert

local placeholder_id = minetest.get_content_id("placeholder:placeholder")

-- local nodename->id cache
local local_nodename_to_id_mapping = {} -- name -> id
local next_unknown_nodeid = -1
local unknown_nodes_id_to_name_mapping = {}

-- deserialization callbacks
local deserialization_callbacks = {} -- nodeid -> fn()
function blockexchange.register_node_deserialize_callback(node_id, fn)
	deserialization_callbacks[node_id] = fn
end

--- place the meta and metadata to the world at the given positions
-- @param pos1 the start pos
-- @param pos2 the end pos
-- @param data the nodeis/param1/param2 data
-- @param metadata the schemapart metdata
function blockexchange.deserialize_part(pos1, pos2, data, metadata, update_light)

	local callbacks = {} -- list of {pos, node_id}

	local mapblock = {
		node_ids = {},
		param1 = {},
		param2 = {}
	}
	local data_length = math_floor(#data / 4)
	for i=1,data_length do
		-- 1, 3, 5 ... 8191
		local node_id_offset = (i * 2) - 1
		local node_id = (string_byte(data, node_id_offset) * 256) +
		string_byte(data, node_id_offset+1) - 32768

		local param1 = string_byte(data, (data_length * 2) + i)
		local param2 = string_byte(data, (data_length * 3) + i)

		table_insert(mapblock.node_ids, node_id)
		table_insert(mapblock.param1, param1)
		table_insert(mapblock.param2, param2)
	end

	local foreign_nodeid_to_name_mapping = {} -- id -> name
	for k, v in pairs(metadata.node_mapping) do
		foreign_nodeid_to_name_mapping[v] = k
	end

	local node_names = {}

	local manip = minetest.get_voxel_manip()
	local e1, e2 = manip:read_from_map(pos1, pos2)
	local area = VoxelArea:new({MinEdge=e1, MaxEdge=e2})

	for i, node_id in ipairs(mapblock.node_ids) do
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

		mapblock.node_ids[i] = local_node_id
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
		local node_id = mapblock.node_ids[j]
		if node_id < 0 then
			-- unknown node, set placeholder
			node_data[i] = placeholder_id
			-- mark node for later
			local hash = hash_node_position({x=x, y=y, z=z})
			placeholder_pos_hashes[hash] = node_id
		else
			-- known node
			node_data[i] = node_id
			if deserialization_callbacks[node_id] then
				-- register callback for this node
				local pos = { x=x, y=y, z=z }
				table.insert(callbacks, { pos=pos, node_id=node_id })
			end
		end

		-- place param1 and param2 regardless of known/unknown node
		param1[i] = mapblock.param1[j]
		param2[i] = mapblock.param2[j]
		j = j + 1
	end
	end
	end

	manip:set_data(node_data)
	manip:set_light_data(param1)
	manip:set_param2_data(param2)
	manip:write_to_map(update_light)

	-- deserialize metadata
	if metadata.metadata and metadata.metadata.meta then
		for pos_str, md in pairs(metadata.metadata.meta) do
			local relative_pos = minetest.string_to_pos(pos_str)
			local absolute_pos = vector.add(pos1, relative_pos)
			local hash = minetest.hash_node_position(absolute_pos)
			local unknown_node_id = placeholder_pos_hashes[hash]
			if unknown_node_id then
				-- extract node name
				local node_name = unknown_nodes_id_to_name_mapping[unknown_node_id]
				-- populate proper placeholder node with metadata
				placeholder.populate(absolute_pos, {name=node_name}, md)
				-- remove from placeholder hashes
				placeholder_pos_hashes[hash] = nil
			else
				-- plain metadata of a known node
				minetest.get_meta(absolute_pos):from_table(md)
			end
		end
	end

	-- go over all non-replaced unknown nodes
	for hash, nodeid in pairs(placeholder_pos_hashes) do
		local node_name = unknown_nodes_id_to_name_mapping[nodeid]
		local pos = minetest.get_position_from_hash(hash)
		placeholder.populate(pos, {name=node_name})
	end

	-- deserialize node timers
	if metadata.metadata and metadata.metadata.timers then
		for pos_str, timer_data in pairs(metadata.metadata.timers) do
			local relative_pos = minetest.string_to_pos(pos_str)
			local absolute_pos = vector.add(pos1, relative_pos)
			minetest.get_node_timer(absolute_pos):set(timer_data.timeout, timer_data.elapsed)
		end
	end

	-- run deserialization callbacks
	for _, cb in ipairs(callbacks) do
		local fn = deserialization_callbacks[cb.node_id]
		if type(fn) == "function" then
			fn(cb.pos)
		end
	end

	return node_names
end
