-- max retries of failed requests over the whole download
local max_retries = 12
-- max time to spend placing parts in a single server step (in microseconds)
local max_step_time_us = 25 * 1000

-- margin around an emerged area: mapgen writes up to one mapblock into
-- neighbouring chunks (decorations, dungeons), so every chunk whose shell
-- overlaps the placed area has to be generated before placing
local emerge_margin = 16

-- emerges the given area (clamped to the schema bounds) including the margin
local function emerge_area(ctx, minp, maxp)
	maxp = vector.new(
		math.min(maxp.x, ctx.pos2.x),
		math.min(maxp.y, ctx.pos2.y),
		math.min(maxp.z, ctx.pos2.z)
	)
	return Promise.emerge_area(
		vector.subtract(minp, emerge_margin),
		vector.add(maxp, emerge_margin)
	)
end

local function get_offset(schemapart)
	return { x = schemapart.offset_x, y = schemapart.offset_y, z = schemapart.offset_z }
end

-- awaits the promise returned by fetch_fn, retries failed requests
-- @return the result of the promise
local function fetch_with_retry(await, ctx, fetch_fn)
	while true do
		local result, err = await(fetch_fn())
		if not err then
			return result
		end
		ctx.retries = ctx.retries + 1
		if ctx.retries > max_retries then
			error("download failed after " .. ctx.retries .. " retries: " .. tostring(err), 0)
		end
		await(Promise.after(5))
	end
end

-- downloads the schemaparts one by one in order
local function fetch_sequential(await, ctx, schema, place)
	local last_part
	while true do
		local schemapart = fetch_with_retry(await, ctx, function()
			if last_part then
				return blockexchange.api.get_next_schemapart(schema.uid, get_offset(last_part))
			else
				return blockexchange.api.get_first_schemapart(schema.uid)
			end
		end)
		if not schemapart then
			-- no more schemaparts
			break
		end
		last_part = schemapart
		if ctx.emerge then
			local part_pos1 = vector.add(ctx.origin, get_offset(schemapart))
			await(emerge_area(ctx, part_pos1, vector.add(part_pos1, 15)))
		end
		place(schemapart)
		await(Promise.after(blockexchange.min_delay))
	end
end

-- downloads the schemaparts in chunks of 5x5x5 parts
local function fetch_chunked(await, ctx, schema, place)
	local size = blockexchange.get_schema_size(schema)
	local chunk_size = blockexchange.chunk_size
	for y = 0, size.y - 1, chunk_size do
	for z = 0, size.z - 1, chunk_size do
	for x = 0, size.x - 1, chunk_size do
		local chunk_offset = { x = x, y = y, z = z }
		-- start generating the target area while the chunk downloads
		local emerged
		if ctx.emerge then
			local minp = vector.add(ctx.origin, chunk_offset)
			emerged = emerge_area(ctx, minp, vector.add(minp, chunk_size - 1))
		end
		local schemaparts = fetch_with_retry(await, ctx, function()
			return blockexchange.api.get_schemapart_chunk(schema.uid, chunk_offset)
		end)
		if emerged then
			await(emerged)
			ctx.step_start = core.get_us_time()
		end

		-- empty chunks resolve with false or an empty list
		for _, schemapart in ipairs(schemaparts or {}) do
			place(schemapart)
			if core.get_us_time() - ctx.step_start > max_step_time_us then
				-- continue in the next server step
				await(Promise.after(0))
				ctx.step_start = core.get_us_time()
			end
		end
		await(Promise.after(blockexchange.min_delay))
		ctx.step_start = core.get_us_time()
	end
	end
	end
end

--- load a schematic asynchronously (internal)
-- @param playername the playername to use in messages
-- @param pos1 lower position to load
-- @param label the label to show in the hud
-- @param fetch_schema function returning a promise that resolves with the schema
-- @param opts table with the optional fields on_schemapart(pos1, pos2), on_schemapart_raw(schemapart)
--  chunked (true: download in chunks, false: download part by part, nil: chunks if the server supports them)
--  and emerge (true: generate the area of each chunk/part right before placing it)
-- @return a promise that resolves if the operation is complete
local function load_schema(playername, pos1, label, fetch_schema, opts)
	local job = {
		hud_icon = "blockexchange_download.png",
		hud_text = "Download '" .. label .. "' starting"
	}

	job.promise = Promise.async(function(await)
		local schema, err = await(fetch_schema())
		if err then
			error("error fetching schema: " .. err, 0)
		elseif not schema then
			error("schema not found: '" .. label .. "'", 0)
		end

		local total_parts
		total_parts, err = await(blockexchange.api.count_next_schemapart_by_mtime(schema.uid, 0))
		if err then
			error("error fetching total parts: " .. err, 0)
		end

		local chunked = opts.chunked
		if chunked == nil then
			chunked = await(blockexchange.api.supports_chunks())
		end

		local ctx = {
			retries = 0,
			step_start = core.get_us_time(),
			-- emerge each chunk/part before placing it
			emerge = opts.emerge,
			origin = pos1,
			pos2 = blockexchange.get_schema_pos2(pos1, schema)
		}
		local current_part = 0
		-- last successfully placed schemapart
		local last_schemapart

		local function place(schemapart)
			if job.cancel then
				error("canceled", 0)
			end

			local part_pos1, part_pos2 = blockexchange.place_schemapart(schemapart, pos1)
			if opts.on_schemapart then
				opts.on_schemapart(part_pos1, part_pos2)
			end
			if opts.on_schemapart_raw then
				opts.on_schemapart_raw(schemapart)
			end
			last_schemapart = schemapart
			current_part = current_part + 1

			local progress_percent = math.floor(current_part / math.max(total_parts or 0, 1) * 100 * 10) / 10
			job.hud_text = "Downloading '" .. label .. "', progress: " .. progress_percent .. " %"
		end

		if chunked then
			fetch_chunked(await, ctx, schema, place)
		else
			fetch_sequential(await, ctx, schema, place)
		end

		return {
			total_parts = total_parts,
			placed_parts = current_part,
			last_schemapart = last_schemapart,
			schema = schema,
			chunked = chunked
		}
	end)

	blockexchange.add_job(playername, job)
	return job.promise
end

--- load a schematic by username and schemaname asynchronously
-- @param playername the playername to use in messages
-- @param pos1 lower position to load
-- @param username the username/owner of the schema
-- @param schemaname the name of the schema
-- @param[opt] opts optional table with the field chunked (see blockexchange.load_by_uid)
-- @return a promise that resolves if the operation is complete
function blockexchange.load(playername, pos1, username, schemaname, opts)
	opts = opts or {}
	return load_schema(playername, pos1, username .. "/" .. schemaname, function()
		return blockexchange.api.get_schema_by_name(username, schemaname, true)
	end, {
		chunked = opts.chunked
	})
end

--- load a schematic by its uid asynchronously
-- @param playername the playername to use in messages
-- @param pos1 lower position to load
-- @param schema_uid the uid of the schema
-- @param[opt] opts optional table with the fields on_schemapart(pos1, pos2),
--  on_schemapart_raw(schemapart) (the downloaded schemapart, after placing it)
--  and chunked (true: download in chunks of 5x5x5 parts, false: download part by part,
--  nil (default): download in chunks if the server supports it)
--  and emerge (true: generate the area of each chunk/part right before placing it,
--  mapgen would overwrite the placed parts otherwise)
-- @return a promise that resolves if the operation is complete
function blockexchange.load_by_uid(playername, pos1, schema_uid, opts)
	opts = opts or {}
	return load_schema(playername, pos1, schema_uid, function()
		return blockexchange.api.get_schema_by_uid(schema_uid, true)
	end, {
		on_schemapart = opts.on_schemapart,
		on_schemapart_raw = opts.on_schemapart_raw,
		chunked = opts.chunked,
		emerge = opts.emerge
	})
end

Promise.register_chatcommand("bx_load", {
    params = "<username> <schemaname>",
    description = "Downloads a schema from the blockexchange to the selected pos1",
    privs = {blockexchange = true},
    func = function(name, param)
        local _, _, username, schemaname = string.find(param, "^([^%s]+)%s+(.*)$")

        if not username or not schemaname then
            return false, "Usage: /bx_load <username> <schemaname>"
        end

        local pos1 = blockexchange.get_pos(1, name)

        if not pos1 then return false, "you need to set /bx_pos1 first!" end

        return blockexchange.load(name, pos1, username, schemaname):next(function(result)
            return "Download complete with " .. result.schema.total_parts .. " parts"
        end)
    end
})
