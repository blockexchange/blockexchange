
local pos1 = {x=0,y=0,z=0}
local pos2 = {x=32,y=32,z=32}

mtt.emerge_area(pos1, pos2)

mtt.register("local save test", function(callback)
    local promise = blockexchange.save("singleplayer", pos1, pos2, "local-save", true)
    promise:next(function()
        callback()
    end)
end)