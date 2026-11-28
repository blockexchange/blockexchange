-- schema spanning two chunks (5x5x5 parts) on the x and z axis
local size = {x=90, y=20, z=90}
local pos1 = {x=300, y=-10, z=0}
local pos2 = vector.add(pos1, vector.subtract(size, 1))
local pos1_sequential = vector.add(pos1, {x=0, y=size.y + 10, z=0})
local pos1_chunked = vector.add(pos1_sequential, {x=0, y=size.y + 10, z=0})

local playername = "singleplayer"
local username = "Testuser"
local schemaname = "chunked_schema" .. math.random(1000)

-- loads the schema at the target position and compares it with the source area
local function load_and_compare(await, target_pos1, opts)
	local result, err = await(blockexchange.load(playername, target_pos1, username, schemaname, opts))
	if err then error("load error: " .. tostring(err), 0) end

	if result.placed_parts ~= result.total_parts then
		error("placed " .. result.placed_parts .. " of " .. result.total_parts .. " parts", 0)
	end

	local target_pos2 = vector.add(target_pos1, vector.subtract(size, 1))
	local success, msg = blockexchange.compare_area(pos1, pos2, target_pos1, target_pos2, { check_param1 = false })
	if not success then
		error("loaded area does not match: " .. msg, 0)
	end
	return result
end

mtt.register("remote load in chunks", {
	timeout = 300,
	func = function(callback)
		Promise.async(function(await)
			local token, err = await(blockexchange.api.get_token(username, "default"))
			if err then error("get_token error: " .. tostring(err), 0) end

			local player_settings = blockexchange.get_player_settings(playername)
			player_settings.token = token
			blockexchange.set_player_settings(playername, player_settings)

			local _
			_, err = await(blockexchange.emerge(playername, pos1, vector.add(pos1_chunked, vector.subtract(size, 1))))
			if err then error("emerge error: " .. tostring(err), 0) end

			-- nodes in the corners and on both sides of the chunk borders (79/80)
			for _, x in ipairs({0, 79, 80, size.x - 1}) do
				for _, y in ipairs({0, size.y - 1}) do
					for _, z in ipairs({0, 79, 80, size.z - 1}) do
						core.set_node(vector.add(pos1, {x=x, y=y, z=z}), { name = "default:stone" })
					end
				end
			end
			core.set_node(vector.add(pos1, {x=40, y=10, z=40}), { name = "default:dirt" })

			_, err = await(blockexchange.save(playername, pos1, pos2, schemaname))
			if err then error("save error: " .. tostring(err), 0) end

			-- part by part
			local result = load_and_compare(await, pos1_sequential, { chunked = false })
			if result.chunked then
				error("sequential download used chunks", 0)
			end

			-- chunked (default if the server supports it)
			local supported = await(blockexchange.api.supports_chunks())
			if not supported then
				print("[blockexchange] server does not support 5x5x5 chunks, skipping the chunked download test")
				return
			end

			result = load_and_compare(await, pos1_chunked)
			if not result.chunked then
				error("download did not use chunks", 0)
			end
		end):next(function()
			callback()
		end):catch(function(err)
			print(err)
			callback(err)
		end)
	end
})
