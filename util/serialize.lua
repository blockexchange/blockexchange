---------
-- serialization functions

local table_insert = table.insert

-- collect nodes with on_timer attributes
local node_names_with_timer = {}
minetest.register_on_mods_loaded(function()
	for _,node in pairs(minetest.registered_nodes) do
		if node.on_timer then
			table_insert(node_names_with_timer, node.name)
		end
	end
	minetest.log("action", "[blockexchange] collected " .. #node_names_with_timer .. " items with node timers")
end)

local air_content_id = minetest.get_content_id("air")
local placeholder_id = minetest.get_content_id("placeholder:placeholder")

-- checks if a table is empty
local function is_empty(tbl)
	if not tbl then
		return true
	end

	for k in pairs(tbl) do
		if k then
			return false
		end
	end
	return true
end

function blockexchange.serialize_part(pos1, pos2, node_count)
	local manip = minetest.get_voxel_manip()
	local e1, e2 = manip:read_from_map(pos1, pos2)
	local area = VoxelArea:new({MinEdge=e1, MaxEdge=e2})

	local node_data = manip:get_data()
	local param1 = manip:get_light_data()
	local param2 = manip:get_param2_data()

	local node_id_count = {}

	-- prepare data structure
	local data = {
		node_ids = {},
		param1 = {},
		param2 = {},
		node_mapping = {}, -- name -> id
		metadata = {},
		size = vector.add( vector.subtract(pos2, pos1), 1 )
	}

	local air_only = true
	local next_unknown_nodeid = -1
	local placeholder_meta_pos_hashes = {}
	local placeholder_node_id_names = {}

	-- loop over all blocks and fill cid,param1 and param2
	for x=pos1.x,pos2.x do
		for y=pos1.y,pos2.y do
			for z=pos1.z,pos2.z do
				local i = area:index(x,y,z)

				local node_id = node_data[i]
				if blockexchange.ignored_content_ids[node_id] then
					-- replace ignore blocks with air
					node_id = air_content_id
				end

				if air_only and node_id ~= air_content_id then
					-- non-air node found, toggle flag
					air_only = false
				end

				-- placeholder case: unwrap and store "raw"
				if node_id == placeholder_id then
					-- unwrap placeholder
					local pos = {x=x, y=y, z=z}
					local hash = minetest.hash_node_position(pos)

					-- unwrap raw node-info
					local meta = minetest.get_meta(pos)
					local original_node, original_metadata = placeholder.unwrap(meta)

					if data.node_mapping[original_node.name] then
						-- already has a mapping
						node_id = data.node_mapping[original_node.name]
					else
						-- create new mapping
						node_id = next_unknown_nodeid
						next_unknown_nodeid = next_unknown_nodeid - 1
						data.node_mapping[original_node.name] = node_id
						placeholder_node_id_names[node_id] = original_node.name
					end

					-- save metadata for later
					placeholder_meta_pos_hashes[hash] = original_metadata
				end

				table_insert(data.node_ids, node_id)
				table_insert(data.param1, param1[i])
				table_insert(data.param2, param2[i])

				local count = node_id_count[node_id] or 0
				node_id_count[node_id] = count + 1
			end
		end
	end

	-- collect statistics and node_id -> name mapping
	node_count = node_count or {}
	for node_id, count in pairs(node_id_count) do
		local node_name = placeholder_node_id_names[node_id] or minetest.get_name_from_content_id(node_id)
		data.node_mapping[node_name] = node_id
		local counter = node_count[node_name] or 0
		node_count[node_name] = counter + count
	end

	-- handle unwrapped placeholder metadata
	for hash, metadata in pairs(placeholder_meta_pos_hashes) do
		local pos = minetest.get_position_from_hash(hash)
		local relative_pos = vector.subtract(pos, pos1)

		data.metadata.meta = data.metadata.meta or {}
		data.metadata.meta[minetest.pos_to_string(relative_pos)] = metadata
	end

	-- serialize metadata
	local pos_with_meta = minetest.find_nodes_with_meta(pos1, pos2)
	for _, pos in ipairs(pos_with_meta) do
		local relative_pos = vector.subtract(pos, pos1)
		local node = minetest.get_node(pos)
		local is_placeholder = node.name == "placeholder:placeholder"
		if not is_placeholder then
			-- not a placeholder, serialize metadata
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

			-- re-check if metadata actually exists (may happen with minetest.find_nodes_with_meta)
			if not is_empty(meta.fields) or not is_empty(meta.inventory) then
				data.metadata.meta = data.metadata.meta or {}
				data.metadata.meta[minetest.pos_to_string(relative_pos)] = meta
			end
		end
	end

	-- serialize node timers
	if #node_names_with_timer > 0 then
		data.metadata.timers = {}
		local list = minetest.find_nodes_in_area(pos1, pos2, node_names_with_timer)
		for _, pos in pairs(list) do
			local timer = minetest.get_node_timer(pos)
			local relative_pos = vector.subtract(pos, pos1)
			if timer:is_started() then
				data.metadata.timers[minetest.pos_to_string(relative_pos)] = {
					timeout = timer:get_timeout(),
					elapsed = timer:get_elapsed()
				}
			end
		end

	end

	return data, node_count, air_only
end

blockexchange.compress_data = Promise.handle_asyncify(function(data)
	local function int_to_bytes(i)
		local x =i + 32768
		local h = math.floor(x/256) % 256;
		local l = math.floor(x % 256);
		return(string.char(h, l));
	end

	-- write node-data in serialized form
	local serialized_data = ""
	local size = #data.node_ids

	for i=1,size do
		serialized_data = serialized_data .. int_to_bytes(data.node_ids[i])
	end
	for i=1,size do
		serialized_data = serialized_data .. string.char(data.param1[i])
	end
	for i=1,size do
		serialized_data = serialized_data .. string.char(data.param2[i])
	end

	return minetest.compress(serialized_data, "deflate")
end)

blockexchange.compress_metadata = Promise.handle_asyncify(function(data)
	local metadata = minetest.write_json({
		node_mapping = data.node_mapping,
		size = data.size,
		metadata = data.metadata
	})

	return minetest.compress(metadata, "deflate")
end)