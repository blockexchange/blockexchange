local size = {x=20, y=20, z=20}
local pos1 = {x=100, y=-10, z=0}
local pos2 = vector.add(pos1, size)

local uploader = "singleplayer"
local username = "Testuser"
local schemaname = "provision_schema" .. math.random(1000)

-- provisions the schematic and checks the placed area and player position
local function provision_and_check(await, playername, schema_uid, origin, opts)
    local player = mtt.join_player(playername)
    player:set_pos({x=0, y=0, z=0})

    local result, err = await(blockexchange.provision(playername, schema_uid, origin, opts))
    mtt.leave_player(playername)
    if err then error("provision error: " .. tostring(err), 0) end

    if result.total_parts < 1 then
        error("no parts provisioned", 0)
    end

    local origin2 = vector.add(origin, size)
    local success, msg = blockexchange.compare_area(pos1, pos2, origin, origin2, { check_param1 = false })
    if not success then
        error("provisioned area does not match: " .. msg, 0)
    end

    return result
end

-- checks the read/write mode (logged in player and synced region with baseline)
local function check_read_write(result, playername, schema_uid, origin)
    local claims = blockexchange.get_claims(playername)
    if not claims or claims.username ~= username then
        error("player '" .. playername .. "' not logged in", 0)
    end

    local entry = result.sync_id and blockexchange.sync.get(result.sync_id)
    if not entry then
        error("no synced region registered", 0)
    end
    if entry.schema_uid ~= schema_uid or entry.owner ~= username or not vector.equals(entry.pos1, origin) then
        error("unexpected synced region: " .. dump(entry), 0)
    end
    if not entry.autosave then
        error("autosave not enabled", 0)
    end
    if not blockexchange.sync.can_write(playername, entry) then
        error("synced region not writable", 0)
    end
    if blockexchange.sync.get_at(origin) ~= entry then
        error("synced region not found at origin", 0)
    end
    if #blockexchange.sync.list_baselines(entry) ~= result.total_parts then
        error("baseline incomplete: " .. #blockexchange.sync.list_baselines(entry) ..
            " of " .. result.total_parts .. " parts", 0)
    end
end

mtt.register("provision schematic by uid", {
    timeout = 300,
    func = function(callback)
        Promise.async(function(await)
            local _
            local token, err = await(blockexchange.api.get_token(username, "default"))
            if err then error("get_token error: " .. tostring(err), 0) end

            local player_settings = blockexchange.get_player_settings(uploader)
            player_settings.token = token
            blockexchange.set_player_settings(uploader, player_settings)

            _, err = await(blockexchange.emerge(uploader, pos1, pos2))
            if err then error("emerge error: " .. tostring(err), 0) end

            -- floor with an air gap above, the provisioned player should end up on top of it
            for x = pos1.x, pos1.x + 3 do
                for z = pos1.z, pos1.z + 3 do
                    core.set_node({x=x, y=pos1.y + 2, z=z}, { name = "default:stone" })
                end
            end

            local save_result
            save_result, err = await(blockexchange.save(uploader, pos1, pos2, schemaname))
            if err then error("save error: " .. tostring(err), 0) end
            local schema_uid = save_result.schema.uid

            -- read-only
            local origin = {x=100, y=30, z=0}
            local result = provision_and_check(await, "provision_ro", schema_uid, origin)
            if result.sync_id or blockexchange.sync.get_at(origin) then
                error("synced region registered in read-only mode", 0)
            end
            if blockexchange.get_claims("provision_ro") then
                error("player logged in in read-only mode", 0)
            end

            -- read/write with username and access_token
            origin = {x=100, y=60, z=0}
            result = provision_and_check(await, "provision_rw1", schema_uid, origin, {
                username = username,
                access_token = "default"
            })
            check_read_write(result, "provision_rw1", schema_uid, origin)

            -- read/write with a raw token
            origin = {x=100, y=90, z=0}
            result = provision_and_check(await, "provision_rw2", schema_uid, origin, { token = token })
            check_read_write(result, "provision_rw2", schema_uid, origin)

            -- invalid access token
            _, err = await(blockexchange.provision("provision_rw3", schema_uid, origin, {
                username = username,
                access_token = "invalid"
            }))
            if not err then
                error("provisioning with an invalid access token should fail", 0)
            end

            -- unknown schema
            _, err = await(blockexchange.provision("provision_ro", "00000000-0000-0000-0000-000000000000", origin))
            if not err then
                error("provisioning an unknown schema should fail", 0)
            end
        end):next(function()
            callback()
        end):catch(function(err)
            print(err)
            callback(err)
        end)
    end
})
