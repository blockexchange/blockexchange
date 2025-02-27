
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
        blockexchange.api.get_token(username, "default"):next(function(token)
            local player_settings = blockexchange.get_player_settings(playername)
			player_settings.token = token
			blockexchange.set_player_settings(playername, player_settings)
            return blockexchange.emerge(playername, pos1, pos2_load)
        end):next(function()
            return blockexchange.save(playername, pos1, pos2, schemaname)
        end):next(function()
            return blockexchange.load(playername, pos1_load, username, schemaname)
        end):next(function()
            local success, msg = blockexchange.compare_area(pos1, pos2, pos1_load, pos2_load, { check_param1 = false })
            if not success then
                print(msg)
                callback("loaded area does not match: " .. msg)
            end
        end):next(function()
            return blockexchange.save_local(playername, pos1, pos2, schemaname)
        end):next(function()
            return blockexchange.load_local(playername, pos1_load, schemaname)
        end):next(function()
            local success, msg = blockexchange.compare_area(pos1, pos2, pos1_load, pos2_load, { check_param1 = false })
            if not success then
                print(msg)
                callback("local loaded area does not match: " .. msg)
            end
        end):next(function()
            callback()
        end):catch(function(err)
            print(err)
            callback(err)
        end)
    end
})