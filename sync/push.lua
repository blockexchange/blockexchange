---------
-- sync push: uploads the local changes of a sync entry as deltas
--
-- every dirty part is compared against its baseline, unchanged parts are skipped,
-- changed parts are patched (only the changed nodes are replaced remotely) or created if they don't exist remotely.
-- the local part becomes the new baseline: remote changes to other nodes of the same part
-- still differ from it and get merged on the next pull.

local sync = blockexchange.sync
local part = sync.part

--- pushes the local changes of the entry
-- @param playername the player whose token is used and who gets the hud job
-- @param entry the sync entry
-- @param[opt] opts table with the optional fields: offsets (list of relative part offsets, defaults to the dirty parts)
--  and force (push even if the entry has no valid baseline)
-- @return a promise resolving with the stats: { parts = <patched/created parts>, created = <created parts>,
--  nodes = <changed nodes>, unchanged = <dirty parts without changes> }
function sync.push(playername, entry, opts)
	opts = opts or {}

	local token = blockexchange.get_player_settings(playername).token
	if not token then
		return Promise.rejected("not logged in")
	end
	if entry.state ~= "ok" and not opts.force then
		return Promise.rejected("sync entry has no valid baseline (state: " .. entry.state .. ")")
	end

	return sync.run_exclusive(entry, "push", function()
		local offsets = opts.offsets or sync.get_dirty_offsets(entry)
		local label = entry.schema_name or entry.schema_uid
		local job = {
			hud_icon = "blockexchange_upload.png",
			hud_text = "Pushing changes of '" .. label .. "'"
		}

		-- part currently in progress, marked dirty again if the push fails
		local current_offset

		job.promise = Promise.async(function(await)
			local stats = { parts = 0, created = 0, nodes = 0, unchanged = 0 }

			for index, offset in ipairs(offsets) do
				local pos1, pos2 = sync.get_part_bounds(entry, offset)

				-- clear the flag before serializing, changes during the upload mark the part again
				current_offset = offset
				sync.clear_dirty(entry, offset)

				local data = blockexchange.serialize_part(pos1, pos2)
				local loc = part.from_serialized(data)
				local baseline = sync.get_baseline(entry, offset)
				local base = baseline and part.from_schemapart(baseline) or part.air(loc.size)
				local filter, changed = part.diff(base, loc)

				if changed == 0 then
					stats.unchanged = stats.unchanged + 1
				else
					local schemapart = await(blockexchange.create_schemapart(data, offset, entry.schema_uid))

					local result, err
					if baseline then
						result, err = await(blockexchange.api.patch_schemapart(token, schemapart, filter))
						if not err and not result then
							-- part vanished remotely, create it
							baseline = nil
						end
					end
					if not err and not baseline then
						result, err = await(blockexchange.api.create_schemapart(token, schemapart))
						stats.created = stats.created + 1
					end

					if err then
						error("push of part " .. core.pos_to_string(offset) .. " failed: " .. err, 0)
					end

					schemapart.mtime = result and result.mtime
					sync.set_baseline(entry, schemapart)
					stats.parts = stats.parts + 1
					stats.nodes = stats.nodes + changed
				end
				current_offset = nil
				sync.save()

				local progress_percent = math.floor(index / #offsets * 100 * 10) / 10
				job.hud_text = "Pushing changes of '" .. label .. "', progress: " .. progress_percent .. " %"

				if job.cancel then
					error("canceled", 0)
				end
				await(Promise.after(blockexchange.min_delay))
			end

			if stats.parts > 0 then
				-- let the server recalculate the mod-list and stats
				local _, err = await(blockexchange.api.update_schemamods(token, entry.schema_uid))
				if err then
					error("mod-list update failed: " .. err, 0)
				end
				_, err = await(blockexchange.api.update_schema_stats(token, entry.schema_uid))
				if err then
					error("stats update failed: " .. err, 0)
				end
			end

			return stats
		end)

		job.promise:catch(function()
			if current_offset then
				sync.mark_dirty(entry, sync.get_part_bounds(entry, current_offset))
				sync.save()
			end
		end)

		blockexchange.add_job(playername, job)
		return job.promise
	end)
end
