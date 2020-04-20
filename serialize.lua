-- collect nodes with on_timer attributes
local node_names_with_timer = {}
minetest.register_on_mods_loaded(function()
	for _,node in pairs(minetest.registered_nodes) do
		if node.on_timer then
			table.insert(node_names_with_timer, node.name)
		end
	end
	minetest.log("action", "[blockexchange] collected " .. #node_names_with_timer .. " items with node timers")
end)

local air_content_id = minetest.get_content_id("air")

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

	-- loop over all blocks and fill cid,param1 and param2
  for x=pos1.x,pos2.x do
  for y=pos1.y,pos2.y do
  for z=pos1.z,pos2.z do
    local i = area:index(x,y,z)
		table.insert(data.node_ids, node_data[i])
		table.insert(data.param1, param1[i])
		table.insert(data.param2, param2[i])

    local node_id = node_data[i]
    local count = node_id_count[node_id] or 0
    node_id_count[node_id] = count + 1
  end
  end
  end

	-- collect statistics and node_id -> name mapping
	node_count = node_count or {}
	for node_id, count in pairs(node_id_count) do
		local node_name = minetest.get_name_from_content_id(node_id)
		if node_name == "ignore" then
			-- replace ignore blocks with air
			node_name = "air"
			node_id = air_content_id
		end

		data.node_mapping[node_name] = node_id
		local counter = node_count[node_name] or 0
		node_count[node_name] = counter + count
	end

	-- serialize metadata
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

		data.metadata.meta = data.metadata.meta or {}
    data.metadata.meta[minetest.pos_to_string(relative_pos)] = meta
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



  return data, node_count
end

-- local nodename->id cache
local local_nodename_to_id_mapping = {} -- name -> id

function blockexchange.deserialize_part(pos1, data)
  local foreign_nodeid_to_name_mapping = {} -- id -> name
  for k, v in pairs(data.node_mapping) do
    foreign_nodeid_to_name_mapping[v] = k
  end

	local pos2 = vector.add(pos1, vector.subtract(data.size, 1))

  local manip = minetest.get_voxel_manip()
  local e1, e2 = manip:read_from_map(pos1, pos2)
	local area = VoxelArea:new({MinEdge=e1, MaxEdge=e2})

  for i, node_id in ipairs(data.node_ids) do
    local node_name = foreign_nodeid_to_name_mapping[node_id]
    local local_node_id = local_nodename_to_id_mapping[node_name]
    if not local_node_id then
      if minetest.registered_nodes[node_name] then
        -- node is locally available
        local_node_id = minetest.get_content_id(node_name)
      else
        -- node is not available here
        -- TODO: make replacements configurable
        local_node_id = minetest.get_content_id("blockexchange:placeholder")
      end
      local_nodename_to_id_mapping[node_name] = local_node_id

    end

    data.node_ids[i] = local_node_id
  end

	local node_data = manip:get_data()
	local param1 = manip:get_light_data()
	local param2 = manip:get_param2_data()

	local j = 1
	for x=pos1.x,pos2.x do
  for y=pos1.y,pos2.y do
  for z=pos1.z,pos2.z do
    local i = area:index(x,y,z)
		node_data[i] = data.node_ids[j]
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
	    minetest.get_meta(absolute_pos):from_table(metadata)
	  end
	end

	-- deserialize node timers
	if data.metadata and data.metadata.timers then
		for pos_str, timer_data in pairs(data.metadata.timers) do
	    local relative_pos = minetest.string_to_pos(pos_str)
	    local absolute_pos = vector.add(pos1, relative_pos)
	    minetest.get_node_timer(absolute_pos):set(timer_data.timeout, timer_data.elapsed)
	  end	end

end
