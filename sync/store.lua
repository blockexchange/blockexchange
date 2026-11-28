---------
-- sync store
-- keeps track of synchronized regions (sync entries) and their baseline schemaparts
--
-- sync entry:
-- {
--   id = "a1b2c3d4",
--   schema_uid = "...", schema_name = "my_house",
--   owner = "username", owner_uid = "...",   -- owner of the remote schematic
--   pos1 = {...}, pos2 = {...},              -- pos1 is the schematic origin
--   playername = "singleplayer",             -- player that created the entry (its token is used for autosave)
--   autosave = false,
--   pulled_mtime = 0,                        -- remote schema mtime up to which remote parts have been merged
--   dirty = { ["0_16_0"] = true },           -- part offsets with possible local changes
--   state = "ok" | "needs_baseline"
-- }
--
-- baseline: the last synchronized state of a schemapart (as exchanged with the server),
-- stored in "<worldpath>/bx_sync/<entry_id>/<x>_<y>_<z>.json".
-- a missing baseline means the part does not exist remotely.

local has_mapsync = core.get_modpath("mapsync")

local storage_key = "sync_v1"
local mapsync_key = "bx_sync"
local baseline_dir = core.get_worldpath() .. "/bx_sync"

local sync = {}
blockexchange.sync = sync

-- id -> entry
local entries = {}
-- id -> areastore id
local store_ids = {}
local area_store = AreaStore()

local function insert_into_store(entry)
	store_ids[entry.id] = area_store:insert_area(entry.pos1, entry.pos2, entry.id)
end

local function create_id()
	local id
	repeat
		id = string.gsub("xxxxxxxx", "x", function()
			return string.format("%x", math.random(0, 0xf))
		end)
	until not entries[id]
	return id
end

---------
-- persistence

function sync.save()
	local data = core.serialize(entries)
	blockexchange.mod_storage:set_string(storage_key, data)
	if has_mapsync then
		mapsync.save_data(mapsync_key, entries)
	end
end

function sync.load()
	local loaded
	if has_mapsync then
		-- prefer the entries persisted along with the map
		loaded = mapsync.load_data(mapsync_key)
	end
	if not loaded then
		local data = blockexchange.mod_storage:get_string(storage_key)
		if data ~= "" then
			loaded = core.deserialize(data)
		end
	end

	entries = loaded or {}
	store_ids = {}
	area_store = AreaStore()
	for _, entry in pairs(entries) do
		entry.dirty = entry.dirty or {}
		insert_into_store(entry)
	end
end

-- load after all mods are loaded (mapsync data backends are registered by then)
core.register_on_mods_loaded(sync.load)

---------
-- entries

--- creates and persists a new sync entry
-- @param def table with the fields: schema (remote schema with uid, name, user_uid, mtime), pos1, pos2, playername
--  and the optional fields id (used if free), owner (username), autosave, pulled_mtime and state
-- @return the new entry
function sync.create(def)
	assert(def.schema and def.schema.uid, "schema with uid required")
	assert(def.pos1 and def.pos2, "pos1 and pos2 required")
	local pos1, pos2 = blockexchange.sort_pos(def.pos1, def.pos2)

	local id = def.id
	if not id or entries[id] or not string.match(id, "^%w+$") then
		id = create_id()
	end

	local entry = {
		id = id,
		schema_uid = def.schema.uid,
		schema_name = def.schema.name,
		owner = def.owner,
		owner_uid = def.schema.user_uid,
		pos1 = pos1,
		pos2 = pos2,
		playername = def.playername,
		autosave = def.autosave == true,
		pulled_mtime = def.pulled_mtime or def.schema.mtime or 0,
		dirty = {},
		state = def.state or "ok"
	}

	entries[entry.id] = entry
	insert_into_store(entry)
	sync.save()
	return entry
end

function sync.get(id)
	return entries[id]
end

--- returns true if the player is logged in as owner of the remote schematic (read/write mode)
function sync.can_write(playername, entry)
	local claims = blockexchange.get_claims(playername)
	return claims ~= nil and entry.owner_uid ~= nil and claims.user_uid == entry.owner_uid
end

--- returns all entries as list
function sync.list()
	local list = {}
	for _, entry in pairs(entries) do
		table.insert(list, entry)
	end
	return list
end

--- returns all entries as list with a stable order: by schematic name, owner and id
function sync.list_sorted()
	local list = sync.list()
	table.sort(list, function(a, b)
		local name_a, name_b = a.schema_name or "", b.schema_name or ""
		if name_a ~= name_b then
			return name_a < name_b
		end
		local owner_a, owner_b = a.owner or "", b.owner or ""
		if owner_a ~= owner_b then
			return owner_a < owner_b
		end
		return a.id < b.id
	end)
	return list
end

--- returns the entry at the given position or nil
function sync.get_at(pos)
	for _, area in pairs(area_store:get_areas_for_pos(pos, false, true)) do
		local entry = entries[area.data]
		if entry then
			return entry
		end
	end
end

--- returns a list of entries intersecting with the given area
function sync.get_in_area(pos1, pos2)
	pos1, pos2 = blockexchange.sort_pos(pos1, pos2)
	local list = {}
	for _, area in pairs(area_store:get_areas_in_area(pos1, pos2, true, false, true)) do
		local entry = entries[area.data]
		if entry then
			table.insert(list, entry)
		end
	end
	return list
end

--- removes the entry and its baseline (the build in the world stays untouched)
function sync.remove(id)
	if not entries[id] then
		return
	end
	if store_ids[id] then
		area_store:remove_area(store_ids[id])
		store_ids[id] = nil
	end
	entries[id] = nil
	core.rmdir(baseline_dir .. "/" .. id, true)
	sync.save()
end

--- removes all entries and baselines
function sync.clear()
	for id in pairs(entries) do
		core.rmdir(baseline_dir .. "/" .. id, true)
	end
	entries = {}
	store_ids = {}
	area_store = AreaStore()
	sync.save()
end

---------
-- busy flags (not persisted), prevents concurrent push/pull operations on the same entry

-- id -> description of the running operation
local busy = {}

--- returns the description of the running operation or nil
function sync.get_busy(entry)
	return busy[entry.id]
end

--- runs the promise-returning function exclusively for the entry
-- @return the promise of the function or a rejected promise if the entry is busy
function sync.run_exclusive(entry, description, fn)
	if busy[entry.id] then
		return Promise.rejected("sync entry is busy: " .. busy[entry.id])
	end
	busy[entry.id] = description
	local ok, promise = pcall(fn)
	if not ok then
		busy[entry.id] = nil
		return Promise.rejected(promise)
	end
	promise:finally(function()
		busy[entry.id] = nil
	end)
	return promise
end

---------
-- part offsets

--- returns the key ("x_y_z") of a relative part offset
function sync.offset_key(offset)
	return offset.x .. "_" .. offset.y .. "_" .. offset.z
end

--- parses a key ("x_y_z") back into a relative part offset
function sync.parse_offset_key(key)
	local x, y, z = string.match(key, "^(%-?%d+)_(%-?%d+)_(%-?%d+)$")
	if x then
		return vector.new(tonumber(x), tonumber(y), tonumber(z))
	end
end

--- returns the relative offset of the part containing the given absolute position
function sync.get_part_offset(entry, pos)
	return blockexchange.get_base_pos(entry.pos1, pos)
end

--- returns the absolute bounds of the part with the given relative offset (clipped to the entry)
function sync.get_part_bounds(entry, offset)
	local pos1 = vector.add(entry.pos1, offset)
	local pos2 = vector.add(pos1, 15)
	pos2.x = math.min(pos2.x, entry.pos2.x)
	pos2.y = math.min(pos2.y, entry.pos2.y)
	pos2.z = math.min(pos2.z, entry.pos2.z)
	return pos1, pos2
end

local function is_valid_offset(entry, offset)
	return offset.x % 16 == 0 and offset.y % 16 == 0 and offset.z % 16 == 0 and
		offset.x >= 0 and offset.y >= 0 and offset.z >= 0 and
		entry.pos1.x + offset.x <= entry.pos2.x and
		entry.pos1.y + offset.y <= entry.pos2.y and
		entry.pos1.z + offset.z <= entry.pos2.z
end

---------
-- dirty tracking (not persisted automatically, call sync.save() afterwards)

--- marks all parts between the absolute positions as dirty
-- @return true if a previously clean part got marked
function sync.mark_dirty(entry, pos1, pos2)
	pos2 = pos2 or pos1
	pos1, pos2 = blockexchange.clip_area(entry.pos1, entry.pos2, blockexchange.sort_pos(pos1, pos2))
	if pos1.x > pos2.x or pos1.y > pos2.y or pos1.z > pos2.z then
		-- no intersection
		return false
	end

	local changed = false
	for _, offset in blockexchange.iterator(entry.pos1, pos1, pos2) do
		local key = sync.offset_key(offset)
		if not entry.dirty[key] then
			entry.dirty[key] = true
			changed = true
		end
	end
	return changed
end

function sync.clear_dirty(entry, offset)
	entry.dirty[sync.offset_key(offset)] = nil
end

function sync.is_dirty(entry, offset)
	return entry.dirty[sync.offset_key(offset)] == true
end

--- returns the list of dirty part offsets
function sync.get_dirty_offsets(entry)
	local list = {}
	for key in pairs(entry.dirty) do
		table.insert(list, sync.parse_offset_key(key))
	end
	return list
end

function sync.count_dirty(entry)
	local count = 0
	for _ in pairs(entry.dirty) do
		count = count + 1
	end
	return count
end

---------
-- baseline

local function get_baseline_filename(entry, offset)
	return baseline_dir .. "/" .. entry.id .. "/" .. sync.offset_key(offset) .. ".json"
end

--- returns the baseline schemapart at the relative offset or nil if the part does not exist remotely
function sync.get_baseline(entry, offset)
	local f = io.open(get_baseline_filename(entry, offset), "r")
	if not f then
		return
	end
	local schemapart = core.parse_json(f:read("*a"))
	f:close()
	return schemapart
end

--- stores the schemapart (offset taken from its offset_x/y/z fields) as baseline
function sync.set_baseline(entry, schemapart)
	local offset = vector.new(schemapart.offset_x, schemapart.offset_y, schemapart.offset_z)
	assert(is_valid_offset(entry, offset), "invalid schemapart offset: " .. core.pos_to_string(offset))

	core.mkdir(baseline_dir .. "/" .. entry.id)
	local ok = core.safe_file_write(get_baseline_filename(entry, offset), core.write_json({
		schema_uid = schemapart.schema_uid,
		offset_x = schemapart.offset_x,
		offset_y = schemapart.offset_y,
		offset_z = schemapart.offset_z,
		mtime = schemapart.mtime,
		data = schemapart.data,
		metadata = schemapart.metadata
	}))
	assert(ok, "could not write baseline for part " .. core.pos_to_string(offset))
end

function sync.remove_baseline(entry, offset)
	os.remove(get_baseline_filename(entry, offset))
end

--- returns the list of relative offsets that have a baseline
function sync.list_baselines(entry)
	local list = {}
	for _, filename in ipairs(core.get_dir_list(baseline_dir .. "/" .. entry.id, false)) do
		local offset = sync.parse_offset_key(string.match(filename, "^(.*)%.json$") or "")
		if offset then
			table.insert(list, offset)
		end
	end
	return list
end
