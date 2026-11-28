-- schema spanning two chunks on the x and z axis
local size = {x=90, y=20, z=90}
local pos1 = {x=500, y=-10, z=0}
local pos2 = vector.add(pos1, vector.subtract(size, 1))
local chest_offset = {x=81, y=5, z=3}

-- mapgen chunk aligned origins ((pos + 32) % 80 == 0), far away from the other tests
local origin_download = {x=-32 + 80 * 20, y=48, z=-32 + 80 * 20}
local origin_cached = {x=-32 + 80 * 25, y=48, z=-32 + 80 * 20}

local playername = "singleplayer"
local username = "Testuser"
local schemaname = "mapgen_schema" .. math.random(1000)

-- waits until all generated chunks of the provisioner are placed
local function wait_for_placement(await, provisioner)
	local start = os.time()
	while provisioner:get_pending_count() > 0 or next(provisioner.regenerating) do
		if os.time() - start > 60 then
			error(provisioner:get_pending_count() .. " chunks still pending", 0)
		end
		await(Promise.after(0.5))
	end
end

local function compare(origin)
	local success, msg = blockexchange.compare_area(pos1, pos2, origin, vector.add(origin, vector.subtract(size, 1)),
		{ check_param1 = false })
	if not success then
		error("provisioned area at " .. core.pos_to_string(origin) .. " does not match: " .. msg, 0)
	end

	local chest_pos = vector.add(origin, chest_offset)
	local infotext = core.get_meta(chest_pos):get_string("infotext")
	if infotext ~= "provisioned" then
		error("chest metadata at " .. core.pos_to_string(chest_pos) .. " missing: '" .. infotext .. "'", 0)
	end
end

mtt.register("mapgen provisioning: alignment check", function(callback)
	assert(blockexchange.get_mapgen_provision_error({x=0, y=0, z=0}))
	assert(blockexchange.get_mapgen_provision_error({x=-32, y=-32, z=-31}))
	assert(not blockexchange.get_mapgen_provision_error({x=-32, y=48, z=-112}))
	assert(not blockexchange.get_mapgen_provision_error(origin_download))

	local provisioner = blockexchange.provision_mapgen("../evil", origin_download)
	assert(not provisioner)
	callback()
end)

mtt.register("mapgen provisioning: download on generation and prefetched", {
	timeout = 300,
	func = function(callback)
		Promise.async(function(await)
			local token, err = await(blockexchange.api.get_token(username, "default"))
			if err then error("get_token error: " .. tostring(err), 0) end

			local player_settings = blockexchange.get_player_settings(playername)
			player_settings.token = token
			blockexchange.set_player_settings(playername, player_settings)

			if not await(blockexchange.api.supports_chunks()) then
				print("[blockexchange] server does not support 5x5x5 chunks, skipping the mapgen provisioning test")
				return
			end

			local _
			_, err = await(blockexchange.emerge(playername, pos1, pos2))
			if err then error("emerge error: " .. tostring(err), 0) end

			-- nodes in the corners and on both sides of the chunk borders, a chest with metadata
			for _, x in ipairs({0, 79, 80, size.x - 1}) do
				for _, y in ipairs({0, size.y - 1}) do
					for _, z in ipairs({0, 79, 80, size.z - 1}) do
						core.set_node(vector.add(pos1, {x=x, y=y, z=z}), { name = "default:stone" })
					end
				end
			end
			local chest_pos = vector.add(pos1, chest_offset)
			core.set_node(chest_pos, { name = "default:chest" })
			core.get_meta(chest_pos):set_string("infotext", "provisioned")

			local save_result
			save_result, err = await(blockexchange.save(playername, pos1, pos2, schemaname))
			if err then error("save error: " .. tostring(err), 0) end
			local schema_uid = save_result.schema.uid

			-- chunks generate before they are downloaded: regenerated after the download
			local provisioner
			provisioner, err = blockexchange.provision_mapgen(schema_uid, origin_download)
			if not provisioner then error("provision_mapgen error: " .. err, 0) end
			_, err = await(provisioner:start())
			if err then error("start error: " .. tostring(err), 0) end

			_, err = await(Promise.emerge_area(origin_download, vector.add(origin_download, vector.subtract(size, 1))))
			if err then error("emerge error: " .. tostring(err), 0) end
			wait_for_placement(await, provisioner)
			compare(origin_download)

			-- prefetched chunks: placed directly while generating
			local cached
			cached, err = blockexchange.provision_mapgen(schema_uid, origin_cached)
			if not cached then error("provision_mapgen error: " .. err, 0) end
			_, err = await(cached:start())
			if err then error("start error: " .. tostring(err), 0) end
			_, err = await(cached:prefetch())
			if err then error("prefetch error: " .. tostring(err), 0) end

			_, err = await(Promise.emerge_area(origin_cached, vector.add(origin_cached, vector.subtract(size, 1))))
			if err then error("emerge error: " .. tostring(err), 0) end
			if cached:get_pending_count() > 0 then
				error("prefetched chunks were not placed while generating", 0)
			end
			compare(origin_cached)
		end):next(function()
			callback()
		end):catch(function(err)
			print(err)
			callback(err)
		end)
	end
})
