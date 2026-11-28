---------
-- decoded schemapart helpers: diff and 3-way merge
--
-- decoded part:
-- {
--   size = {x=16, y=16, z=16},
--   count = 4096,
--   names = { [i] = "default:stone" },
--   param1 = { [i] = 0 }, param2 = { [i] = 0 },
--   meta = { [i] = { fields = {...}, inventory = {...} } },   -- sparse
--   timers = { [i] = { timeout = 1, elapsed = 0 } }            -- sparse
-- }
-- node order: x, then y, then z (z changes fastest), same as the serialized data and the server

local string_byte, string_char, math_floor = string.byte, string.char, math.floor
local table_concat = table.concat

local part = {}
blockexchange.sync.part = part

-- patchfilter flags, see the blockexchange server PatchFilterType
part.PATCH_NODENAME = 0x01
part.PATCH_PARAM1 = 0x02
part.PATCH_PARAM2 = 0x04
part.PATCH_METADATA = 0x08
part.PATCH_ALL = 0x0F

local function get_count(size)
	return size.x * size.y * size.z
end

--- returns the 1-based node index of the relative position
function part.get_index(size, pos)
	return (pos.x * size.y + pos.y) * size.z + pos.z + 1
end

--- returns the relative position of the 1-based node index
function part.get_pos(size, index)
	local i = index - 1
	return {
		x = math_floor(i / (size.y * size.z)),
		y = math_floor(i / size.z) % size.y,
		z = i % size.z
	}
end

-- converts a metadata table keyed by position strings into an index-keyed table
local function index_metadata(size, tbl)
	local result = {}
	for pos_str, value in pairs(tbl or {}) do
		local pos = core.string_to_pos(pos_str)
		if pos then
			result[part.get_index(size, pos)] = value
		end
	end
	return result
end

local function new_part(size)
	return {
		size = { x = size.x, y = size.y, z = size.z },
		count = get_count(size),
		names = {},
		param1 = {},
		param2 = {},
		meta = {},
		timers = {}
	}
end

--- creates an air-only part, used as baseline for parts that do not exist remotely
function part.air(size)
	local p = new_part(size)
	for i = 1, p.count do
		p.names[i] = "air"
		p.param1[i] = 0
		p.param2[i] = 0
	end
	return p
end

--- decodes a compressed schemapart (as exchanged with the server)
function part.from_schemapart(schemapart)
	local data, metadata = blockexchange.unpack_schemapart(schemapart)
	local p = new_part(metadata.size)

	local id_to_name = {}
	for name, id in pairs(metadata.node_mapping) do
		id_to_name[id] = name
	end

	local count = p.count
	assert(#data == count * 4, "unexpected data length " .. #data .. " for " .. count .. " nodes")
	for i = 1, count do
		local offset = (i * 2) - 1
		local node_id = (string_byte(data, offset) * 256) + string_byte(data, offset + 1) - 32768
		p.names[i] = id_to_name[node_id] or "air"
		p.param1[i] = string_byte(data, (count * 2) + i)
		p.param2[i] = string_byte(data, (count * 3) + i)
	end

	local md = metadata.metadata or {}
	p.meta = index_metadata(p.size, md.meta)
	p.timers = index_metadata(p.size, md.timers)
	return p
end

--- decodes the result of blockexchange.serialize_part
function part.from_serialized(data)
	local p = new_part(data.size)

	local id_to_name = {}
	for name, id in pairs(data.node_mapping) do
		id_to_name[id] = name
	end

	for i = 1, p.count do
		p.names[i] = id_to_name[data.node_ids[i]] or "air"
		p.param1[i] = data.param1[i]
		p.param2[i] = data.param2[i]
	end

	local md = data.metadata or {}
	p.meta = index_metadata(p.size, md.meta)
	p.timers = index_metadata(p.size, md.timers)
	return p
end

--- encodes the part into the blockexchange.serialize_part format (input for blockexchange.create_schemapart)
function part.to_serialized(p)
	local data = {
		node_ids = {},
		param1 = {},
		param2 = {},
		node_mapping = {},
		metadata = {},
		size = { x = p.size.x, y = p.size.y, z = p.size.z }
	}

	local next_id = 0
	for i = 1, p.count do
		local name = p.names[i]
		local id = data.node_mapping[name]
		if not id then
			id = next_id
			next_id = next_id + 1
			data.node_mapping[name] = id
		end
		data.node_ids[i] = id
		data.param1[i] = p.param1[i]
		data.param2[i] = p.param2[i]
	end

	for i, value in pairs(p.meta) do
		data.metadata.meta = data.metadata.meta or {}
		data.metadata.meta[core.pos_to_string(part.get_pos(p.size, i))] = value
	end
	for i, value in pairs(p.timers) do
		data.metadata.timers = data.metadata.timers or {}
		data.metadata.timers[core.pos_to_string(part.get_pos(p.size, i))] = value
	end

	return data
end

--- encodes the node data of the serialized part into the raw byte format (input for blockexchange.deserialize_part)
function part.to_bytes(data)
	local count = #data.node_ids
	local buf = {}
	for i = 1, count do
		local x = data.node_ids[i] + 32768
		buf[i] = string_char(math_floor(x / 256) % 256, x % 256)
	end
	for i = 1, count do
		buf[count + i] = string_char(data.param1[i])
	end
	for i = 1, count do
		buf[(count * 2) + i] = string_char(data.param2[i])
	end
	return table_concat(buf)
end

---------
-- comparison

local function is_empty(v)
	return v == nil or (type(v) == "table" and next(v) == nil)
end

-- deep comparison, empty tables are equal to nil
local function deep_equal(a, b)
	if is_empty(a) and is_empty(b) then
		return true
	end
	if type(a) ~= "table" or type(b) ~= "table" then
		return a == b
	end
	for k, v in pairs(a) do
		if not deep_equal(v, b[k]) then
			return false
		end
	end
	for k, v in pairs(b) do
		if a[k] == nil and not is_empty(v) then
			return false
		end
	end
	return true
end
part.deep_equal = deep_equal

-- timers are compared by timeout only, the elapsed time changes continuously
local function timer_equal(a, b)
	if a == nil or b == nil then
		return a == b
	end
	return math.abs((a.timeout or 0) - (b.timeout or 0)) < 0.001
end

local function metadata_equal(a, i, b, j)
	return deep_equal(a.meta[i], b.meta[j]) and timer_equal(a.timers[i], b.timers[j])
end

--- compares a single node of two parts (param1/light is ignored)
function part.node_equal(a, i, b, j)
	j = j or i
	return a.names[i] == b.names[j] and
		a.param2[i] == b.param2[j] and
		metadata_equal(a, i, b, j)
end

local function check_size(a, b)
	assert(vector.equals(a.size, b.size),
		"part size mismatch: " .. core.pos_to_string(a.size) .. " vs " .. core.pos_to_string(b.size))
end

--- computes the patchfilter to transform the baseline into the local part
-- param1 (light) is only transferred along with a changed node name
-- @param base the baseline part
-- @param loc the local part
-- @return the patchfilter string (one byte per node)
-- @return the number of changed nodes
function part.diff(base, loc)
	check_size(base, loc)
	local filter = {}
	local changed = 0
	for i = 1, base.count do
		local f = 0
		if base.names[i] ~= loc.names[i] then
			f = part.PATCH_ALL
		else
			if base.param2[i] ~= loc.param2[i] then
				f = f + part.PATCH_PARAM2
			end
			if not metadata_equal(base, i, loc, i) then
				f = f + part.PATCH_METADATA
			end
		end
		if f ~= 0 then
			changed = changed + 1
		end
		filter[i] = string_char(f)
	end
	return table_concat(filter), changed
end

local function copy_node(dst, src, i)
	dst.names[i] = src.names[i]
	dst.param1[i] = src.param1[i]
	dst.param2[i] = src.param2[i]
	dst.meta[i] = src.meta[i]
	dst.timers[i] = src.timers[i]
end

--- 3-way merge of the local and remote part with a common baseline
-- nodes only changed on one side are taken from that side,
-- nodes changed on both sides (to different values) are conflicts and resolved by the policy
-- @param base the common baseline
-- @param loc the local part
-- @param remote the remote part
-- @param policy conflict resolution: "mine" (default) or "theirs"
-- @return the merged part
-- @return stats table: remote_nodes (nodes taken from remote that differ locally),
--  conflicts (nodes changed on both sides), local_nodes (merged nodes differing from remote),
--  remote_indices (list of node indices taken from remote)
function part.merge(base, loc, remote, policy)
	check_size(base, loc)
	check_size(base, remote)

	local merged = new_part(base.size)
	local stats = {
		remote_nodes = 0,
		conflicts = 0,
		local_nodes = 0,
		remote_indices = {}
	}

	for i = 1, base.count do
		local remote_changed = not part.node_equal(remote, i, base)
		local take_remote = false

		if remote_changed and not part.node_equal(remote, i, loc) then
			if part.node_equal(loc, i, base) then
				-- only changed remotely
				take_remote = true
			else
				-- changed on both sides
				stats.conflicts = stats.conflicts + 1
				take_remote = policy == "theirs"
			end
		end

		if take_remote then
			copy_node(merged, remote, i)
			stats.remote_nodes = stats.remote_nodes + 1
			table.insert(stats.remote_indices, i)
		else
			copy_node(merged, loc, i)
			if not part.node_equal(loc, i, remote) then
				stats.local_nodes = stats.local_nodes + 1
			end
		end
	end

	return merged, stats
end

--- writes the part into the world, the previous local part is needed to clean up removed metadata and timers
-- @param pos1 lower position of the part
-- @param p the part to write
-- @param previous the part that was there before (local state)
function part.write(pos1, p, previous)
	local pos2 = vector.add(pos1, vector.subtract(p.size, 1))
	local data = part.to_serialized(p)
	blockexchange.deserialize_part(pos1, pos2, part.to_bytes(data), {
		node_mapping = data.node_mapping,
		metadata = data.metadata
	})

	-- remove metadata and timers that don't exist in the written part anymore
	for i in pairs(previous.meta) do
		if is_empty(p.meta[i]) then
			core.get_meta(vector.add(pos1, part.get_pos(p.size, i))):from_table(nil)
		end
	end
	for i in pairs(previous.timers) do
		if not p.timers[i] then
			core.get_node_timer(vector.add(pos1, part.get_pos(p.size, i))):stop()
		end
	end

	if core.get_modpath("mapsync") then
		mapsync.mark_changed(pos1, pos2)
	end
end
