---------
-- initial sync transfers: upload or download a schematic and register it as sync entry with baseline

local sync = blockexchange.sync

local function check_overlap(pos1, pos2)
	local existing = sync.get_in_area(pos1, pos2)
	if #existing > 0 then
		return "area overlaps with synced region '" .. existing[1].id .. "' (" ..
			(existing[1].schema_name or existing[1].schema_uid) .. ")"
	end
end

--- uploads the area as new schematic and registers it as sync entry
-- @param playername the uploading player (needs to be logged in)
-- @param pos1 first position
-- @param pos2 second position
-- @param schemaname the name of the new schematic
-- @param[opt] opts table with the optional field autosave
-- @return a promise resolving with { entry = <sync entry>, total_parts, total_size, schema }
function sync.upload(playername, pos1, pos2, schemaname, opts)
	opts = opts or {}
	pos1, pos2 = blockexchange.sort_pos(pos1, pos2)

	local claims = blockexchange.get_claims(playername)
	if not claims then
		return Promise.rejected("not logged in")
	end
	local overlap_err = check_overlap(pos1, pos2)
	if overlap_err then
		return Promise.rejected(overlap_err)
	end

	local parts = {}
	return blockexchange.save(playername, pos1, pos2, schemaname, {
		on_part = function(schemapart)
			table.insert(parts, schemapart)
		end
	}):next(function(result)
		local entry = sync.create({
			schema = result.schema,
			owner = claims.username,
			pos1 = pos1,
			pos2 = pos2,
			playername = playername,
			autosave = opts.autosave,
			pulled_mtime = result.schema.mtime
		})
		for _, schemapart in ipairs(parts) do
			sync.set_baseline(entry, schemapart)
		end

		result.entry = entry
		return result
	end)
end

-- fetches the remote schema and checks that it still fits the entry
local function fetch_matching_schema(await, entry)
	local schema, err = await(blockexchange.api.get_schema_by_uid(entry.schema_uid))
	if err then
		error("error fetching schema: " .. err, 0)
	elseif not schema then
		error("remote schema not found: " .. entry.schema_uid, 0)
	end
	if not vector.equals(blockexchange.get_schema_pos2(entry.pos1, schema), entry.pos2) then
		error("remote schema size does not match the synced region", 0)
	end
	return schema
end

--- downloads all remote parts of the entry into the baseline without placing them
-- existing baselines are removed first
-- @return a promise resolving with the number of remote parts
function sync.fetch_baseline(entry)
	return Promise.async(function(await)
		for _, offset in ipairs(sync.list_baselines(entry)) do
			sync.remove_baseline(entry, offset)
		end

		local count = 0
		local schemapart, err = await(blockexchange.api.get_first_schemapart(entry.schema_uid))
		while true do
			if err then
				error("error fetching schemapart: " .. err, 0)
			elseif not schemapart then
				break
			end
			sync.set_baseline(entry, schemapart)
			count = count + 1
			schemapart, err = await(blockexchange.api.get_next_schemapart(entry.schema_uid, {
				x = schemapart.offset_x,
				y = schemapart.offset_y,
				z = schemapart.offset_z
			}))
		end
		return count
	end)
end

--- resolves an entry without valid baseline (state "needs_baseline") with local changes taking precedence:
-- the remote parts become the baseline and all parts are marked dirty, the next push uploads the differences
-- @return a promise resolving with the entry
function sync.resolve_local(entry)
	return Promise.async(function(await)
		local schema = fetch_matching_schema(await, entry)
		local _, err = await(sync.fetch_baseline(entry))
		if err then
			error(err, 0)
		end
		entry.pulled_mtime = schema.mtime
		entry.state = "ok"
		sync.mark_dirty(entry, entry.pos1, entry.pos2)
		sync.save()
		return entry
	end)
end

--- resolves an entry without valid baseline (state "needs_baseline") with the remote schematic taking precedence:
-- the remote schematic is placed again, parts that don't exist remotely are cleared
-- @return a promise resolving with the entry
function sync.resolve_remote(playername, entry)
	return sync.run_exclusive(entry, "pull", function()
		return Promise.async(function(await)
			local schema = fetch_matching_schema(await, entry)

			for _, offset in ipairs(sync.list_baselines(entry)) do
				sync.remove_baseline(entry, offset)
			end
			local _, err = await(blockexchange.load_by_uid(playername, entry.pos1, entry.schema_uid, {
				on_schemapart_raw = function(schemapart)
					sync.set_baseline(entry, schemapart)
				end
			}))
			if err then
				error("download failed: " .. err, 0)
			end

			-- parts without remote counterpart are air remotely
			for _, offset in blockexchange.iterator(entry.pos1, entry.pos1, entry.pos2) do
				if not sync.get_baseline(entry, offset) then
					local pos1, pos2 = sync.get_part_bounds(entry, offset)
					local data, _, air_only = blockexchange.serialize_part(pos1, pos2)
					if not air_only then
						local loc = sync.part.from_serialized(data)
						sync.part.write(pos1, sync.part.air(loc.size), loc)
					end
				end
			end

			entry.dirty = {}
			entry.pulled_mtime = schema.mtime
			entry.state = "ok"
			sync.save()
			return entry
		end)
	end)
end

--- links the area at pos1 to an existing remote schematic of the same size, the local state takes precedence
-- (all parts are marked dirty, the next push uploads the differences)
-- @param playername the player
-- @param pos1 the lower position of the area
-- @param schema_uid the uid of the remote schematic
-- @param[opt] opts table with the optional fields owner (username) and autosave
-- @return a promise resolving with the new entry
function sync.link(playername, pos1, schema_uid, opts)
	opts = opts or {}
	return Promise.async(function(await)
		local schema, err = await(blockexchange.api.get_schema_by_uid(schema_uid))
		if err then
			error("error fetching schema: " .. err, 0)
		elseif not schema then
			error("schema not found: " .. schema_uid, 0)
		end

		local pos2 = blockexchange.get_schema_pos2(pos1, schema)
		local overlap_err = check_overlap(pos1, pos2)
		if overlap_err then
			error(overlap_err, 0)
		end

		local entry = sync.create({
			schema = schema,
			owner = opts.owner,
			pos1 = pos1,
			pos2 = pos2,
			playername = playername,
			autosave = opts.autosave,
			state = "needs_baseline"
		})

		local _
		_, err = await(sync.resolve_local(entry))
		if err then
			sync.remove(entry.id)
			error(err, 0)
		end
		return entry
	end)
end

--- downloads a schematic and registers it as sync entry
-- @param playername the player who gets the hud job
-- @param pos1 the lower position to place the schematic at
-- @param schema_uid the uid of the remote schematic
-- @param[opt] opts table with the optional fields owner (username of the schematic owner) and autosave
-- @return a promise resolving with { entry = <sync entry>, total_parts, schema }
function sync.download(playername, pos1, schema_uid, opts)
	opts = opts or {}

	return Promise.async(function(await)
		-- fetch the schema before the parts, changes during the download get pulled later
		local schema, err = await(blockexchange.api.get_schema_by_uid(schema_uid))
		if err then
			error("error fetching schema: " .. err, 0)
		elseif not schema then
			error("schema not found: " .. schema_uid, 0)
		end

		local pos2 = blockexchange.get_schema_pos2(pos1, schema)
		local overlap_err = check_overlap(pos1, pos2)
		if overlap_err then
			error(overlap_err, 0)
		end

		local parts = {}
		local result
		result, err = await(blockexchange.load_by_uid(playername, pos1, schema_uid, {
			on_schemapart_raw = function(schemapart)
				table.insert(parts, schemapart)
			end
		}))
		if err then
			error("download failed: " .. err, 0)
		end

		local entry = sync.create({
			schema = schema,
			owner = opts.owner,
			pos1 = pos1,
			pos2 = pos2,
			playername = playername,
			autosave = opts.autosave,
			pulled_mtime = schema.mtime
		})
		for _, schemapart in ipairs(parts) do
			sync.set_baseline(entry, schemapart)
		end

		result.entry = entry
		return result
	end)
end
