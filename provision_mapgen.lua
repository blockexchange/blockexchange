---------
-- mapgen provisioning: places a remote schematic chunk by chunk while the map generates
-- (configured with "mode": "mapgen" in "<worldpath>/bx_provision.json", see provision.lua)
--
-- requirements:
-- * mapgen chunksize 5: one mapgen chunk (80 nodes) is exactly one schemapart chunk
-- * the origin is aligned to the mapgen chunks: (origin + 32) % 80 == 0 on every axis
-- * the target area is not generated yet, already generated chunks are left alone
--
-- the chunks are only ever placed from on_generated into the mapgen voxelmanip: the engine writes the
-- one-mapblock border of the neighbouring chunks back after generating a chunk, nodes placed
-- asynchronously into a chunk next to a generating one could get reverted that way.
--
-- * all chunks get prefetched into "<worldpath>/bx_provision/<schema_uid>/"
-- * a generating chunk that is already downloaded is placed right away
-- * a generating chunk that is not downloaded yet is marked as pending (persisted in the mod storage),
--   it gets deleted and generated again as soon as its download is available

local chunk_size = blockexchange.chunk_size
-- mapgen chunks start at -32 + n * 80 with a chunksize of 5 (offset: -floor(chunksize / 2) mapblocks)
local mapgen_chunk_offset = -32
local max_retries = 12

local function get_mapgen_chunksize()
	if core.get_mapgen_chunksize then
		-- vector since 5.15
		return core.get_mapgen_chunksize()
	end
	local chunksize = tonumber(core.get_mapgen_setting("chunksize"))
	return { x = chunksize, y = chunksize, z = chunksize }
end

--- checks if the origin can be used for mapgen provisioning
-- @param origin the lower position of the schematic
-- @return nil if the origin is usable, an error message otherwise
function blockexchange.get_mapgen_provision_error(origin)
	local chunksize = get_mapgen_chunksize()
	if chunksize.x ~= 5 or chunksize.y ~= 5 or chunksize.z ~= 5 then
		return "mapgen provisioning needs a mapgen chunksize of 5, current: " .. core.pos_to_string(chunksize)
	end

	local aligned = {}
	for _, axis in ipairs({ "x", "y", "z" }) do
		aligned[axis] = origin[axis] - ((origin[axis] - mapgen_chunk_offset) % chunk_size)
	end
	if not vector.equals(aligned, origin) then
		return "position " .. core.pos_to_string(origin) .. " is not aligned to the mapgen chunks, " ..
			"next lower aligned position: " .. core.pos_to_string(aligned)
	end
end

local function offset_key(offset)
	return offset.x .. "," .. offset.y .. "," .. offset.z
end

local function get_part_offset(schemapart)
	return { x = schemapart.offset_x, y = schemapart.offset_y, z = schemapart.offset_z }
end

-- active provisioners
local provisioners = {}

local Provisioner = {}
Provisioner.__index = Provisioner

--- creates a mapgen provisioner and registers it for the on_generated callback
-- @param schema_uid the uid of the remote schematic
-- @param origin the lower position of the schematic, aligned to the mapgen chunks
-- @return the provisioner, call :start() (and optionally :prefetch()) on it
-- @return nil and an error message if the origin or the schema_uid is not usable
function blockexchange.provision_mapgen(schema_uid, origin)
	if type(schema_uid) ~= "string" or not schema_uid:match("^[%w%-]+$") then
		return nil, "invalid schema_uid: " .. dump(schema_uid)
	end
	local err = blockexchange.get_mapgen_provision_error(origin)
	if err then
		return nil, err
	end

	local self = setmetatable({
		schema_uid = schema_uid,
		origin = vector.copy(origin),
		cache_dir = core.get_worldpath() .. "/bx_provision/" .. schema_uid,
		storage_key = "provision_mapgen_pending/" .. schema_uid .. "@" .. core.pos_to_string(origin),
		-- offset_key -> offset of generated chunks that still have to be placed
		pending = {},
		-- offset_key -> promise of running chunk downloads
		downloads = {},
		-- offset_key -> true for chunks waiting for their download and regeneration
		regenerating = {},
		-- remote schema, nil until known
		schema = nil
	}, Provisioner)

	local pending_json = blockexchange.mod_storage:get_string(self.storage_key)
	if pending_json ~= "" then
		self.pending = core.parse_json(pending_json) or {}
	end
	self.schema = self:read_json("schema.json")

	table.insert(provisioners, self)
	return self
end

function Provisioner:read_json(filename)
	local file = io.open(self.cache_dir .. "/" .. filename, "r")
	if not file then
		return nil
	end
	local content = file:read("*a")
	file:close()
	return content ~= "" and core.parse_json(content) or nil
end

local function chunk_filename(offset)
	return "chunk_" .. offset.x .. "_" .. offset.y .. "_" .. offset.z .. ".json"
end

--- returns the cached schemaparts of the chunk, nil if not downloaded yet
function Provisioner:read_chunk(offset)
	local file = io.open(self.cache_dir .. "/" .. chunk_filename(offset), "r")
	if not file then
		return nil
	end
	local content = file:read("*a")
	file:close()
	-- empty chunks are stored as empty list
	return content ~= "" and core.parse_json(content) or {}
end

function Provisioner:has_chunk(offset)
	local file = io.open(self.cache_dir .. "/" .. chunk_filename(offset), "r")
	if file then
		file:close()
		return true
	end
	return false
end

function Provisioner:save_pending()
	blockexchange.mod_storage:set_string(self.storage_key, next(self.pending) and core.write_json(self.pending) or "")
end

-- returns true if the chunk offset is inside the schema, nil if the schema is not known yet
function Provisioner:is_in_bounds(offset)
	if not self.schema then
		return nil
	end
	local size = blockexchange.get_schema_size(self.schema)
	return offset.x >= 0 and offset.y >= 0 and offset.z >= 0 and
		offset.x < size.x and offset.y < size.y and offset.z < size.z
end

--- returns a promise resolving with the schemaparts of the chunk (from the cache or the server)
function Provisioner:fetch_chunk(offset)
	local parts = self:read_chunk(offset)
	if parts then
		return Promise.resolve(parts)
	end

	local key = offset_key(offset)
	if not self.downloads[key] then
		self.downloads[key] = blockexchange.api.get_schemapart_chunk(self.schema_uid, offset):next(function(result)
			local list = result or {}
			core.safe_file_write(self.cache_dir .. "/" .. chunk_filename(offset),
				#list > 0 and core.write_json(list) or "[]")
			self.downloads[key] = nil
			return list
		end):catch(function(err)
			self.downloads[key] = nil
			return Promise.rejected(err)
		end)
	end
	return self.downloads[key]
end

-- deletes and generates the chunk again, retries if it was not placed afterwards
-- (deleting fails for blocks that are not saved yet with some map backends)
function Provisioner:regenerate(offset, attempt)
	local key = offset_key(offset)
	local minp = vector.add(self.origin, offset)
	local maxp = vector.add(minp, chunk_size - 1)
	blockexchange.log("action", "regenerating provisioned chunk at " .. core.pos_to_string(minp))

	-- on_generated places the downloaded chunk this time
	core.delete_area(minp, maxp)
	core.emerge_area(minp, maxp, function(_, _, remaining)
		if remaining > 0 then
			return
		end
		if not self.pending[key] then
			-- placed
			self.regenerating[key] = nil
		elseif attempt < max_retries then
			core.after(5, function()
				self:regenerate(offset, attempt + 1)
			end)
		else
			-- stays pending, retried on the next start
			self.regenerating[key] = nil
			blockexchange.log("error", "regenerating provisioned chunk at " .. core.pos_to_string(minp) .. " failed")
		end
	end)
end

-- regenerates a pending chunk as soon as it is downloaded
function Provisioner:regenerate_when_available(offset, retries)
	local key = offset_key(offset)
	if not retries then
		if self.regenerating[key] then
			-- already scheduled
			return
		end
		self.regenerating[key] = true
		retries = 0
	end

	self:fetch_chunk(offset):next(function()
		-- never delete from inside on_generated
		return Promise.after(0)
	end):next(function()
		self:regenerate(offset, 0)
	end):catch(function(err)
		if retries >= max_retries then
			-- stays pending, retried on the next start
			self.regenerating[key] = nil
			blockexchange.log("error", "download of provisioned chunk " .. key .. " failed: " .. tostring(err))
			return
		end
		core.after(5, function()
			self:regenerate_when_available(offset, retries + 1)
		end)
	end)
end

-- places the schemaparts of the chunk into the mapgen voxelmanip (only callable from on_generated)
function Provisioner:place_mapgen(schemaparts)
	if #schemaparts == 0 then
		return
	end

	local vm, emin, emax = core.get_mapgen_object("voxelmanip")
	local area = VoxelArea:new({ MinEdge = emin, MaxEdge = emax })
	local node_data = vm:get_data()
	local node_param1 = vm:get_light_data()
	local node_param2 = vm:get_param2_data()

	local finishers = {}
	for _, schemapart in ipairs(schemaparts) do
		local data, metadata = blockexchange.unpack_schemapart(schemapart)
		local pos1 = vector.add(self.origin, get_part_offset(schemapart))
		local pos2 = vector.add(pos1, vector.subtract(metadata.size, 1))
		local finish = blockexchange.deserialize_part_into(area, node_data, node_param1, node_param2,
			pos1, pos2, data, metadata)
		table.insert(finishers, finish)
	end

	vm:set_data(node_data)
	vm:set_light_data(node_param1)
	vm:set_param2_data(node_param2)
	vm:calc_lighting()
	vm:write_to_map()

	-- metadata, placeholders, timers and callbacks
	for _, finish in ipairs(finishers) do
		finish()
	end
end

function Provisioner:on_generated(minp)
	local offset = vector.subtract(minp, self.origin)
	if offset.x % chunk_size ~= 0 or offset.y % chunk_size ~= 0 or offset.z % chunk_size ~= 0 then
		-- not aligned (chunksize changed?)
		return
	end
	if self:is_in_bounds(offset) == false then
		return
	end

	local key = offset_key(offset)
	local schemaparts = self:is_in_bounds(offset) and self:read_chunk(offset)
	if schemaparts then
		self:place_mapgen(schemaparts)
		if self.pending[key] then
			self.pending[key] = nil
			self:save_pending()
		end
		return
	end

	-- not downloaded yet (or the schema is not known yet): regenerate later
	self.pending[key] = offset
	self:save_pending()
	if self.schema then
		self:regenerate_when_available(offset)
	end
end

--- fetches the schema (or uses the cached one if the server is not reachable) and resumes the pending chunks
-- the chunk cache is cleared if the remote schema changed, fails if the server does not support 5x5x5 chunks
-- @return a promise resolving with the schema
function Provisioner:start()
	return Promise.async(function(await)
		local schema, err = await(blockexchange.api.get_schema_by_uid(self.schema_uid))
		if schema and not err and not await(blockexchange.api.supports_chunks()) then
			-- older servers return chunks with 4x4x4 parts
			error("the server does not support schemapart chunks with 5x5x5 parts (api version 1.2 needed)", 0)
		end
		if err or not schema then
			if not self.schema then
				error("error fetching schema '" .. self.schema_uid .. "': " .. tostring(err or "not found"), 0)
			end
			blockexchange.log("warning", "fetching schema '" .. self.schema_uid .. "' failed, using the cached one: " ..
				tostring(err or "not found"))
			schema = self.schema
		end

		if not self.schema or self.schema.mtime ~= schema.mtime then
			-- new or changed remote schema
			core.rmdir(self.cache_dir, true)
			core.mkdir(self.cache_dir)
			core.safe_file_write(self.cache_dir .. "/schema.json", core.write_json({
				uid = schema.uid,
				mtime = schema.mtime,
				size_x = schema.size_x,
				size_y = schema.size_y,
				size_z = schema.size_z
			}))
		end
		self.schema = schema

		-- resume chunks that generated before their download was available
		for key, offset in pairs(self.pending) do
			if self:is_in_bounds(offset) then
				self:regenerate_when_available(offset)
			else
				self.pending[key] = nil
			end
		end
		self:save_pending()

		return schema
	end)
end

--- downloads all chunks of the schema into the cache (call after :start())
-- @return a promise resolving with the number of downloaded chunks
function Provisioner:prefetch()
	return Promise.async(function(await)
		local size = blockexchange.get_schema_size(self.schema)
		local count = 0
		local retries = 0
		for y = 0, size.y - 1, chunk_size do
		for z = 0, size.z - 1, chunk_size do
		for x = 0, size.x - 1, chunk_size do
			local offset = { x = x, y = y, z = z }
			while not self:has_chunk(offset) do
				local _, err = await(self:fetch_chunk(offset))
				if err then
					retries = retries + 1
					if retries > max_retries then
						error("prefetch failed after " .. retries .. " retries: " .. tostring(err), 0)
					end
					await(Promise.after(5))
				else
					count = count + 1
					await(Promise.after(blockexchange.min_delay))
				end
			end
		end
		end
		end
		return count
	end)
end

--- returns the number of chunks that generated but are not placed yet
function Provisioner:get_pending_count()
	local count = 0
	for _ in pairs(self.pending) do
		count = count + 1
	end
	return count
end

core.register_on_generated(function(minp)
	for _, provisioner in ipairs(provisioners) do
		provisioner:on_generated(minp)
	end
end)
