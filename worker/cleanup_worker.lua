
-- nodenames without metadata
local metadata_free_nodenames = {
    ["air"] = true
}

-- nodeid's with zero param2 value
local param2_zero_nodeids = {
    [minetest.CONTENT_AIR] = true,
    [minetest.CONTENT_UNKNOWN] = true,
    [minetest.CONTENT_IGNORE] = true
}

function blockexchange.cleanup_worker(ctx)
    if not ctx.current_pos then
        -- done
        ctx.promise:resolve(ctx.result)
        return
    end

    if ctx.cancel then
        ctx.promise:reject("canceled")
        return
    end

    local pos1 = ctx.current_pos
    local pos2 = vector.add(pos1, 15)
    pos2.x = math.min(pos2.x, ctx.pos2.x)
    pos2.y = math.min(pos2.y, ctx.pos2.y)
    pos2.z = math.min(pos2.z, ctx.pos2.z)

    -- load area
    minetest.load_area(pos1, pos2)

    -- clear stray metadata
    local pos_list = minetest.find_nodes_with_meta(pos1, pos2)
    for _, pos in ipairs(pos_list) do
        local node = minetest.get_node(pos)
        if metadata_free_nodenames[node.name] then
            -- clear metadata
            minetest.get_meta(pos):from_table(nil)
            ctx.result.meta = ctx.result.meta + 1
        end
    end

    -- clear invalid param2 values
    local manip = minetest.get_voxel_manip()
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
            ctx.result.param2 = ctx.result.param2 + 1
        end
    end
    end
    end

    if dirty then
        manip:set_param2_data(param2)
        manip:write_to_map()
    end

    -- shift coordinates
    ctx.current_pos, ctx.rel_pos, ctx.progress = ctx.iterator()

    -- increment stats
    ctx.current_part = ctx.current_part + 1
    ctx.progress_percent = math.floor(ctx.progress * 100 * 10) / 10
    minetest.after(0.1, blockexchange.cleanup_worker, ctx)
end
