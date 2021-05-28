
-- all allowed axes
local allowed_axes = {
  ["x+"] = true,
  ["x-"] = true,
  ["y+"] = true,
  ["y-"] = true,
  ["z+"] = true,
  ["z-"] = true,
}

minetest.register_chatcommand("bx_expand", {
  params = "<x+|x-|y+|y-|z+|z-> <nodecount>",
	description = "expands the current schematic with the given nodecount/axis and uploads the new part",
  privs = { blockexchange = true },
	func = blockexchange.api_check_wrapper(function(name, param)
    local _, _, axis, nodecount_str = string.find(param, "^([^%s]+)%s+(.*)$")
    -- check for both params
    if not axis or not nodecount_str then
      return false, "Usage: /bx_expand <+x|-x|+y|-y|+z|-z> <nodes>"
    end

    -- check if the nodecount is a number and greater than 0
    local nodecount = tonumber(nodecount_str)
    if not nodecount or nodecount <= 0 then
      return false, "invalid nodecount specified"
    end

    -- floor() the nodecount
    nodecount = math.floor(nodecount)

    -- check if the axis is valid
    if not allowed_axes[axis] then
      return false, "not a valid axis: " .. axis
    end

    -- check if the player is online
    local player = minetest.get_player_by_name(name)
    if not player then
      return false, "Player not found"
    end

    -- check if an area is at the player position
    local pos = player:get_pos()
    local area = blockexchange.get_area(pos, pos)
    if not area then
      return false, "No area found at the current position"
    end

    -- dispatch command
    blockexchange.expand(name, area, axis, nodecount)
		return true, "axis: '" .. axis .. "' nodecount: '" .. nodecount .. "'"
  end)
})
