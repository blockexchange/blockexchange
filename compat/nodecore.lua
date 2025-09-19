
assert(nc, "nodecore namespace found")
assert(type(nc.storebox_on_rightclick) == "function", "storebox function found")

-- intercept nodecore function and use pos-argument for change-trigger
local function intercept_nc_function(name)
    local old_fn = nc[name]
    assert(type(old_fn) == "function", "function found on nc-namespace: '" .. name .. "'")
    nc[name] = function(...)
        local args = {...}
        local pos = args[1]
        blockexchange.mark_changed(pos)
        return old_fn(...)
    end
end

intercept_nc_function("storebox_on_rightclick")
intercept_nc_function("storebox_on_punch")
