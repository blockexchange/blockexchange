
local pos1 = {x=0,y=0,z=0}
local pos2 = {x=10,y=10,z=32}

mtt.emerge_area(pos1, pos2)

mtt.register("local save test", function(callback)
    local promise = blockexchange.save("singleplayer", pos1, pos2, "local-save", true)
    promise:next(function()
        blockexchange.set_pos(1, "singleplayer", pos1)
        return blockexchange.allocate("singleplayer", pos1, "", "local-save", true)
    end):next(function()
        callback()
    end):catch(function(err)
        print(err)
        callback(err)
    end)
end)