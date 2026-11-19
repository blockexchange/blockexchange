---------
-- ignored content ids

blockexchange.ignored_content_ids = {}

--- add a nodename to ignore (set to air on save)
-- @param nodename the nodename to ignore
function blockexchange.ignore_node(nodename)
    if not core.registered_nodes[nodename] then
        -- node not available
        return
    end
    local node_id = core.get_content_id(nodename)
    blockexchange.ignored_content_ids[node_id] = true
end

blockexchange.ignore_node("ignore")

-- register default ignored nodes

-- ignore vacuum
if core.get_modpath("vacuum") then
    blockexchange.ignore_node("vacuum:vacuum")
end

if core.get_modpath("nc_api_active") then
    blockexchange.ignore_node("nc_api_active:shade")
    for i = 1, 14 do
        blockexchange.ignore_node("nc_api_active:light" .. i)
    end
end