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
