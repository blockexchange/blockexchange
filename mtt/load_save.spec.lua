
local size = {x=30, y=30, z=30}
local pos1 = {x=0, y=-10, z=0}
local pos2 = vector.add(pos1, size)
local pos1_load = {x=0, y=30, z=0 }
local pos2_load = vector.add(pos1_load, size)

local playername = "singleplayer"
local username = "Testuser"
local schemaname = "test_schema" .. math.random(1000)

mtt.register("remote save test", {
    timeout = 300,
    func = function(callback)
        Promise.async(function(await)
            local _
            local token, err = await(blockexchange.api.get_token(username, "default"))
            if err then error("get_token error: " .. tostring(err), 0) end

            local player_settings = blockexchange.get_player_settings(playername)
            player_settings.token = token
            blockexchange.set_player_settings(playername, player_settings)

            _, err = await(blockexchange.emerge(playername, pos1, pos2_load))
            if err then error("emerge error: " .. tostring(err), 0) end

            -- place some non-air nodes so the schema has actual parts and mods
            core.set_node(pos1, { name = "default:stone" })
            core.set_node(vector.add(pos1, 20), { name = "default:dirt" })

            -- remote save/load
            _, err = await(blockexchange.save(playername, pos1, pos2, schemaname))
            if err then error("save error: " .. tostring(err), 0) end

            local load_result
            load_result, err = await(blockexchange.load(playername, pos1_load, username, schemaname))
            if err then error("load error: " .. tostring(err), 0) end
            if not load_result.last_schemapart then
                error("load result has no last_schemapart", 0)
            end

            local success, msg = blockexchange.compare_area(pos1, pos2, pos1_load, pos2_load, { check_param1 = false })
            if not success then
                error("loaded area does not match: " .. msg, 0)
            end

            -- local save/load
            _, err = await(blockexchange.save_local(playername, pos1, pos2, schemaname))
            if err then error("save_local error: " .. tostring(err), 0) end

            -- mods.json has to be a list of mod names
            local zipfile = io.open(blockexchange.get_local_filename(schemaname), "rb")
            local zip = mtzip.unzip(zipfile)
            local mods = core.parse_json(zip:get("mods.json"))
            zipfile:close()
            if type(mods) ~= "table" or mods[1] ~= "default" then
                error("unexpected mods.json content: " .. dump(mods), 0)
            end

            local alloc_result
            alloc_result, err = await(blockexchange.allocate(playername, pos1_load, playername, schemaname, true))
            if err then error("allocate error: " .. tostring(err), 0) end
            if alloc_result.missing_mods ~= "" then
                error("unexpected missing mods: " .. alloc_result.missing_mods, 0)
            end

            _, err = await(blockexchange.load_local(playername, pos1_load, schemaname))
            if err then error("load_local error: " .. tostring(err), 0) end

            success, msg = blockexchange.compare_area(pos1, pos2, pos1_load, pos2_load, { check_param1 = false })
            if not success then
                error("local loaded area does not match: " .. msg, 0)
            end
        end):next(function()
            callback()
        end):catch(function(err)
            print(err)
            callback(err)
        end)
    end
})
