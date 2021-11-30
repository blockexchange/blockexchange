---------
-- ignored content ids

blockexchange.ignored_content_ids = {}

--- add a nodename to ignore (set to air on save)
-- @param nodename the nodename to ignore
function blockexchange.ignore_node(nodename)
    local node_id = minetest.get_content_id(nodename)
    blockexchange.ignored_content_ids[node_id] = true
end

blockexchange.ignore_node("ignore")

-- register default ignored nodes

-- ignore vacuum
if minetest.get_modpath("vacuum") then
    blockexchange.ignore_node("vacuum:vacuum")
end