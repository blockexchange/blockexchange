---------
-- sync pull: downloads remote changes and merges them into the local world
--
-- two steps, so the ui can show a summary before anything is changed:
-- 1. sync.fetch(): downloads all remote parts newer than the entry's pulled_mtime (kept in memory)
-- 2. sync.apply(): 3-way merges every fetched part with the local state and the baseline, writes it
--    and stores the remote part as new baseline
-- sync.analyze() computes the merge stats of a fetched plan without changing anything.

local sync = blockexchange.sync
local part = sync.part

local function get_schema_size(schema)
	return { x = schema.size_x, y = schema.size_y, z = schema.size_z }
end

local function get_entry_size(entry)
	return vector.add(vector.subtract(entry.pos2, entry.pos1), 1)
end

local function get_offset(schemapart)
	return vector.new(schemapart.offset_x, schemapart.offset_y, schemapart.offset_z)
end

-- merges a single remote part with the current local state and its baseline
-- @return the merged part, the merge stats, the local part and the lower position of the part
local function merge_part(entry, schemapart, policy)
	local offset = get_offset(schemapart)
	local pos1, pos2 = sync.get_part_bounds(entry, offset)

	local loc = part.from_serialized(blockexchange.serialize_part(pos1, pos2))
	local remote = part.from_schemapart(schemapart)
	local baseline = sync.get_baseline(entry, offset)
	local base = baseline and part.from_schemapart(baseline) or part.air(loc.size)

	local merged, stats = part.merge(base, loc, remote, policy)
	return merged, stats, loc, pos1
end

--- fetches the remote changes of the entry
-- @param entry the sync entry
-- @return a promise resolving with the plan: { entry, schema, parts = {schemapart, ...}, mtime = <new pulled_mtime> }
function sync.fetch(entry)
	return Promise.async(function(await)
		local schema, err = await(blockexchange.api.get_schema_by_uid(entry.schema_uid))
		if err then
			error("error fetching schema: " .. err, 0)
		elseif not schema then
			error("remote schema not found: " .. entry.schema_uid, 0)
		end

		if not vector.equals(get_schema_size(schema), get_entry_size(entry)) then
			error("remote schema size changed: " .. core.pos_to_string(get_schema_size(schema)) ..
				" local: " .. core.pos_to_string(get_entry_size(entry)), 0)
		end

		local parts = {}
		local mtime = entry.pulled_mtime
		while true do
			local schemapart
			schemapart, err = await(blockexchange.api.get_next_schemapart_by_mtime(entry.schema_uid, mtime))
			if err then
				error("error fetching schemapart: " .. err, 0)
			elseif not schemapart then
				break
			end
			table.insert(parts, schemapart)
			mtime = schemapart.mtime
		end

		if #parts == 0 then
			-- nothing changed in the parts, catch up with the schema mtime
			mtime = math.max(entry.pulled_mtime, schema.mtime)
		end

		return {
			entry = entry,
			schema = schema,
			parts = parts,
			mtime = mtime
		}
	end)
end

--- computes the merge stats of a fetched plan against the current local state (no changes are made)
-- @return { parts = <fetched parts>, changed_parts = <parts with remote changes to apply>,
--  conflict_parts = <parts with conflicts>, conflicts = <conflicting nodes>, remote_nodes = <nodes to apply> }
function sync.analyze(plan)
	local result = { parts = #plan.parts, changed_parts = 0, conflict_parts = 0, conflicts = 0, remote_nodes = 0 }
	for _, schemapart in ipairs(plan.parts) do
		local _, stats = merge_part(plan.entry, schemapart, "mine")
		if stats.remote_nodes > 0 then
			result.changed_parts = result.changed_parts + 1
		end
		if stats.conflicts > 0 then
			result.conflict_parts = result.conflict_parts + 1
		end
		result.conflicts = result.conflicts + stats.conflicts
		result.remote_nodes = result.remote_nodes + stats.remote_nodes
	end
	return result
end

--- applies a fetched plan
-- @param playername the player who gets the hud job
-- @param plan the result of sync.fetch()
-- @param policy conflict resolution: "mine" (keep local nodes), "theirs" (take remote nodes)
--  or "abort" (reject without changes if there are any conflicts)
-- @return a promise resolving with the stats: { parts = <applied parts>, remote_nodes = <applied remote nodes>,
--  conflicts = <conflicting nodes>, local_parts = <parts with remaining local changes> }
function sync.apply(playername, plan, policy)
	local entry = plan.entry
	policy = policy or "abort"

	if policy == "abort" then
		local analysis = sync.analyze(plan)
		if analysis.conflicts > 0 then
			return Promise.rejected(analysis.conflicts .. " conflicting nodes in " ..
				analysis.conflict_parts .. " parts")
		end
	end

	return sync.run_exclusive(entry, "pull", function()
		local label = entry.schema_name or entry.schema_uid
		local job = {
			hud_icon = "blockexchange_download.png",
			hud_text = "Pulling changes of '" .. label .. "'"
		}

		job.promise = Promise.async(function(await)
			local stats = { parts = 0, remote_nodes = 0, conflicts = 0, local_parts = 0 }

			for index, schemapart in ipairs(plan.parts) do
				-- conflicts appearing after the analysis keep the local nodes in "abort" mode
				local merged, merge_stats, loc, pos1 = merge_part(entry, schemapart, policy == "theirs" and "theirs" or "mine")
				local offset = get_offset(schemapart)

				if merge_stats.remote_nodes > 0 then
					part.write(pos1, merged, loc)
					stats.parts = stats.parts + 1
					stats.remote_nodes = stats.remote_nodes + merge_stats.remote_nodes
				end
				stats.conflicts = stats.conflicts + merge_stats.conflicts

				-- the remote part is the new common state, remaining local changes stay dirty
				sync.set_baseline(entry, schemapart)
				if merge_stats.local_nodes > 0 then
					sync.mark_dirty(entry, sync.get_part_bounds(entry, offset))
					stats.local_parts = stats.local_parts + 1
				else
					sync.clear_dirty(entry, offset)
				end
				sync.save()

				local progress_percent = math.floor(index / #plan.parts * 100 * 10) / 10
				job.hud_text = "Pulling changes of '" .. label .. "', progress: " .. progress_percent .. " %"

				if job.cancel then
					error("canceled", 0)
				end
				await(Promise.after(blockexchange.min_delay))
			end

			entry.pulled_mtime = plan.mtime
			sync.save()
			return stats
		end)

		blockexchange.add_job(playername, job)
		return job.promise
	end)
end

--- fetches and applies the remote changes
-- @see sync.apply
function sync.pull(playername, entry, policy)
	return sync.fetch(entry):next(function(plan)
		return sync.apply(playername, plan, policy)
	end)
end
