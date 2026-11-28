---------
-- migration of the removed area-tracking ("areas_v3") to synced regions
--
-- migrated regions have no baseline (state "needs_baseline"), the authoritative side
-- (remote or local) has to be chosen in the /bx_sync status page.
-- the legacy data is kept as backup ("areas_v3_migrated" in the mod storage, "bx_areas_migrated" in mapsync)

local has_mapsync = core.get_modpath("mapsync")

local sync = blockexchange.sync

local legacy_storage_key = "areas_v3"
local legacy_mapsync_key = "bx_areas"

-- returns the legacy area map (area_id -> area) or nil
local function load_legacy_areas()
	local area_map
	if has_mapsync then
		area_map = mapsync.load_data(legacy_mapsync_key)
	end
	if not area_map then
		local json = blockexchange.mod_storage:get_string(legacy_storage_key)
		if json ~= "" then
			area_map = core.parse_json(json)
		end
	end
	if type(area_map) == "table" and next(area_map) then
		return area_map
	end
end

local function is_valid_area(area)
	return type(area) == "table" and
		type(area.schema_uid) == "string" and
		type(area.pos1) == "table" and type(area.pos2) == "table"
end

--- migrates legacy areas to synced regions without baseline
-- areas overlapping existing synced regions are skipped
-- @param area_map table of area_id -> area (pos1, pos2, schema_uid, name, mtime, username, playername, autosave)
-- @return the number of migrated and skipped areas
function sync.migrate_areas(area_map)
	local migrated, skipped = 0, 0
	for area_id, area in pairs(area_map) do
		if not is_valid_area(area) then
			blockexchange.log("warning", "skipping invalid legacy area '" .. tostring(area_id) .. "'")
			skipped = skipped + 1
		elseif #sync.get_in_area(area.pos1, area.pos2) > 0 then
			blockexchange.log("warning", "skipping legacy area '" .. tostring(area_id) ..
				"', it overlaps an existing synced region")
			skipped = skipped + 1
		else
			local entry = sync.create({
				id = type(area_id) == "string" and area_id or nil,
				schema = { uid = area.schema_uid, name = area.name, mtime = area.mtime },
				owner = area.username,
				pos1 = area.pos1,
				pos2 = area.pos2,
				playername = area.playername,
				autosave = area.autosave == true,
				pulled_mtime = area.mtime or 0,
				state = "needs_baseline"
			})
			blockexchange.log("action", "migrated legacy area '" .. tostring(area_id) ..
				"' to synced region '" .. entry.id .. "'")
			migrated = migrated + 1
		end
	end
	return migrated, skipped
end

--- fetches the missing owner uids of synced regions (migrated regions only know the owner name)
-- @return a promise resolving with the number of updated entries
function sync.update_missing_owners()
	return Promise.async(function(await)
		local updated = 0
		for _, entry in ipairs(sync.list()) do
			if not entry.owner_uid then
				local schema = await(blockexchange.api.get_schema_by_uid(entry.schema_uid))
				if schema then
					entry.owner_uid = schema.user_uid
					entry.schema_name = schema.name
					updated = updated + 1
				end
			end
		end
		if updated > 0 then
			sync.save()
		end
		return updated
	end)
end

--- migrates the persisted legacy areas (mapsync or mod storage) and removes them afterwards (a backup is kept)
-- @return the number of migrated and skipped areas
function sync.migrate_legacy()
	local area_map = load_legacy_areas()
	if not area_map then
		return 0, 0
	end

	local migrated, skipped = sync.migrate_areas(area_map)
	blockexchange.log("action", "migrated " .. migrated .. " legacy areas to synced regions, skipped " .. skipped)

	-- keep a backup and remove the legacy data
	blockexchange.mod_storage:set_string(legacy_storage_key .. "_migrated", core.write_json(area_map))
	blockexchange.mod_storage:set_string(legacy_storage_key, "")
	if has_mapsync then
		mapsync.save_data(legacy_mapsync_key .. "_migrated", area_map)
		mapsync.save_data(legacy_mapsync_key, nil)
	end
	return migrated, skipped
end

core.register_on_mods_loaded(function()
	-- runs after sync.load() (registered earlier)
	sync.migrate_legacy()

	if blockexchange.is_online then
		core.after(1, function()
			sync.update_missing_owners():catch(function(err)
				blockexchange.log("warning", "could not update the owners of synced regions: " .. tostring(err))
			end)
		end)
	end
end)
