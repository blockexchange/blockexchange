
local ignored_mod_names = {
    ["air"] = true,
    ["ignore"] = true
}

function blockexchange.collect_node_count(node_count, mod_names)
    -- collect mod count info
    for k, _ in pairs(node_count) do
        local i = 1
        for str in string.gmatch(k, "([^:]+)") do
            if i == 1 and not ignored_mod_names[str] then
                mod_names[str] = true
            end
            i = i + 1
        end
    end
end