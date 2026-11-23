---------
-- schematic provisioning
-- downloads the schematic configured in "<worldpath>/bx_provision.json"
-- on the first player join and moves the player into the build
--
-- file structure:
-- {
--   "schema_uid": "a681b2e3-f44a-47e5-b862-5c4714709040",
--   "position": { "x": 0, "y": 0, "z": 0 },
--   "username": "myuser",          (optional, login with an access token)
--   "access_token": "abcdef",      (optional, login with an access token)
--   "token": "<jwt>"               (optional, raw jwt token)
-- }
--
-- if authentication is provided the schematic is placed in read/write mode:
-- the player gets logged in and the area is registered with autosave enabled

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

-- resolves the jwt token from the auth options, returns nil if no authentication is configured
local function resolve_token(await, opts)
	if opts.token then
		return opts.token
	elseif opts.username and opts.access_token then
		local token, err = await(blockexchange.api.get_token(opts.username, opts.access_token))
		if err then
			error("login failed: " .. err, 0)
		end
		return token
	end
end

--- emerges the target area, downloads the schematic and moves the player to the first solid schemapart
-- @param playername the player to use for the job and to move afterwards
-- @param schema_uid the uid of the remote schematic
-- @param origin the lower position to place the schematic at
-- @param[opt] opts authentication options: token (raw jwt) or username and access_token,
--  if provided the player gets logged in and the area is registered with autosave enabled
-- @return a promise that resolves with { total_parts = number, player_pos = pos|nil, area_id = string|nil }
function blockexchange.provision(playername, schema_uid, origin, opts)
	opts = opts or {}
	-- list of {pos1, pos2} of placed schemaparts in download order
	local placed_parts = {}

	return Promise.async(function(await)
		local schema, err = await(blockexchange.api.get_schema_by_uid(schema_uid))
		if err then
			error("error fetching schema: " .. err, 0)
		elseif not schema then
			error("schema not found: '" .. schema_uid .. "'", 0)
		end

		-- authentication (optional)
		local claims
		local token = resolve_token(await, opts)
		if token then
			local valid
			valid, err = await(blockexchange.api.get_claims(token))
			if err then
				error("token check failed: " .. err, 0)
			elseif not valid then
				error("invalid or expired token", 0)
			end

			claims = blockexchange.parse_token(token)
			if claims.user_uid ~= schema.user_uid then
				error("user '" .. claims.username .. "' is not the owner of schema '" .. schema_uid .. "'", 0)
			end

			-- log the player in
			local player_settings = blockexchange.get_player_settings(playername)
			player_settings.token = token
			blockexchange.set_player_settings(playername, player_settings)
		end

		-- generate the target area first, mapgen would overwrite the placed parts otherwise
		local pos2 = blockexchange.get_schema_pos2(origin, schema)
		local _
		_, err = await(blockexchange.emerge(playername, origin, pos2))
		if err then
			error("emerge error: " .. err, 0)
		end

		local load_result
		load_result, err = await(blockexchange.load_by_uid(playername, origin, schema_uid, {
			on_schemapart = function(part_pos1, part_pos2)
				table.insert(placed_parts, { part_pos1, part_pos2 })
			end
		}))
		if err then
			error("load error: " .. err, 0)
		end

		local area_id
		if claims then
			-- read/write mode: replace previously tracked areas and register the new one
			for _, area in ipairs(blockexchange.get_areas_in_area(origin, pos2)) do
				blockexchange.remove_area(area.id)
			end
			area_id = blockexchange.register_area(origin, pos2, playername, claims.username, load_result.schema)
			blockexchange.get_area_by_id(area_id).autosave = true
			blockexchange.save_areas()
		end

		-- move the player to the first solid schemapart
		local player_pos
		local player = core.get_player_by_name(playername)
		if player then
			for _, part in ipairs(placed_parts) do
				player_pos = find_standing_pos(part[1], part[2])
				if player_pos then
					player:set_pos(player_pos)
					break
				end
			end
		end

		return {
			total_parts = #placed_parts,
			player_pos = player_pos,
			area_id = area_id
		}
	end)
end

-- configuration file

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

for _, key in ipairs({ "username", "access_token", "token" }) do
	if config[key] ~= nil and type(config[key]) ~= "string" then
		error("[blockexchange] invalid config in '" .. config_path .. "': " .. key .. " has to be a string", 0)
	end
end
if (config.username == nil) ~= (config.access_token == nil) then
	error("[blockexchange] invalid config in '" .. config_path .. "': username and access_token are both required", 0)
end

local schema_uid = config.schema_uid
local auth_opts = {
	token = config.token,
	username = config.username,
	access_token = config.access_token
}
local origin = vector.round(vector.new(position.x, position.y, position.z))
local storage_key = "provisioned_schematic"
-- provisioning state: uid and position, re-provision if one of them changes
local storage_value = schema_uid .. "@" .. core.pos_to_string(origin)
local in_progress = false

core.register_on_joinplayer(function(player)
	if in_progress or blockexchange.mod_storage:get_string(storage_key) == storage_value then
		-- already provisioned or currently running
		return
	end

	local playername = player:get_player_name()
	in_progress = true
	blockexchange.provision(playername, schema_uid, origin, auth_opts):next(function(result)
		blockexchange.mod_storage:set_string(storage_key, storage_value)
		blockexchange.log("action", "provisioned schematic '" .. schema_uid .. "' with " .. result.total_parts .. " parts")
		core.chat_send_player(playername, "[blockexchange] provisioned schematic with " .. result.total_parts .. " parts")
	end):catch(function(e)
		blockexchange.log("error", "provisioning of schematic '" .. schema_uid .. "' failed: " .. tostring(e))
		core.chat_send_player(playername, "[blockexchange] provisioning failed: " .. tostring(e))
	end):finally(function()
		in_progress = false
	end)
end)
