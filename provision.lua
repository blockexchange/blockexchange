---------
-- schematic provisioning
-- downloads the schematic configured in "<worldpath>/bx_provision.json"
-- on the first player join and moves the player into the build
--
-- file structure:
-- {
--   "schema_uid": "a681b2e3-f44a-47e5-b862-5c4714709040",
--   "position": { "x": 0, "y": 0, "z": 0 }
-- }

local config_path = core.get_worldpath() .. "/bx_provision.json"
local file = io.open(config_path, "r")
if not file then
	return
end
local config = core.parse_json(file:read("*a"))
file:close()

if type(config) ~= "table" or type(config.schema_uid) ~= "string" or config.schema_uid == "" then
	error("[blockexchange] invalid config in '" .. config_path .. "': schema_uid missing", 0)
end

local position = config.position
if type(position) ~= "table" or
	type(position.x) ~= "number" or type(position.y) ~= "number" or type(position.z) ~= "number" then
	error("[blockexchange] invalid config in '" .. config_path .. "': position missing", 0)
end

local schema_uid = config.schema_uid
local origin = vector.round(vector.new(position.x, position.y, position.z))
local storage_key = "provisioned_schematic"
-- provisioning state: uid and position, re-provision if one of them changes
local storage_value = schema_uid .. "@" .. core.pos_to_string(origin)
local in_progress = false

local function is_walkable(pos)
	local node = core.get_node(pos)
	local def = core.registered_nodes[node.name]
	return def and def.walkable
end

-- returns a standing position in the given area (solid node with two free nodes above) or nil
local function find_standing_pos(pos1, pos2)
	for x = pos1.x, pos2.x do
		for z = pos1.z, pos2.z do
			for y = pos2.y, pos1.y, -1 do
				local pos = { x = x, y = y, z = z }
				if is_walkable(pos) and
					not is_walkable({ x = x, y = y + 1, z = z }) and
					not is_walkable({ x = x, y = y + 2, z = z }) then
					return { x = x, y = y + 1, z = z }
				end
			end
		end
	end
end

local function provision(playername)
	in_progress = true
	-- list of {pos1, pos2} of placed schemaparts in download order
	local placed_parts = {}

	return Promise.async(function(await)
		local schema, err = await(blockexchange.api.get_schema_by_uid(schema_uid))
		if err then
			error("error fetching schema: " .. err, 0)
		elseif not schema then
			error("schema not found: '" .. schema_uid .. "'", 0)
		end

		-- generate the target area first, mapgen would overwrite the placed parts otherwise
		local _
		_, err = await(blockexchange.emerge(playername, origin, blockexchange.get_schema_pos2(origin, schema)))
		if err then
			error("emerge error: " .. err, 0)
		end

		_, err = await(blockexchange.load_by_uid(playername, origin, schema_uid, {
			on_schemapart = function(pos1, pos2)
				table.insert(placed_parts, { pos1, pos2 })
			end
		}))
		if err then
			error("load error: " .. err, 0)
		end

		blockexchange.mod_storage:set_string(storage_key, storage_value)

		-- move the player to the first solid schemapart
		local player = core.get_player_by_name(playername)
		if player then
			for _, part in ipairs(placed_parts) do
				local pos = find_standing_pos(part[1], part[2])
				if pos then
					player:set_pos(pos)
					break
				end
			end
		end

		return #placed_parts
	end):next(function(count)
		blockexchange.log("action", "provisioned schematic '" .. schema_uid .. "' with " .. count .. " parts")
		core.chat_send_player(playername, "[blockexchange] provisioned schematic with " .. count .. " parts")
	end):catch(function(e)
		blockexchange.log("error", "provisioning of schematic '" .. schema_uid .. "' failed: " .. tostring(e))
		core.chat_send_player(playername, "[blockexchange] provisioning failed: " .. tostring(e))
	end):finally(function()
		in_progress = false
	end)
end

core.register_on_joinplayer(function(player)
	if in_progress or blockexchange.mod_storage:get_string(storage_key) == storage_value then
		-- already provisioned or currently running
		return
	end
	provision(player:get_player_name())
end)
