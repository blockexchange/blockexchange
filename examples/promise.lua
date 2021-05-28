-- luacheck: no unused
-- Source: https://github.com/Billiam/promise.lua

-- create a new promise
local promise = Promise.new()

-- register callbacks
promise:next(function(value)
    -- value == 2
end):catch(function(err)
    print("something went wrong: " .. err)
end)

-- resolve promise somewhere in an async code
promise:resolve(2)

-- example with the blockexchange info endpoint
blockexchange.api.get_info():next(function(info)
    info = {
        api_version_major = 1,
        api_version_minor = 1,
        owner = "someone",
        name = "central exchange"
    }
end):catch(function(err)
    print("something went wrong: " .. err)
end)