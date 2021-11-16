
--- calculates the mapblock position from a node position
-- @param pos the node-position
-- @return the mapblock position
function blockexchange.get_mapblock(pos)
	return vector.floor( vector.divide(pos, 16))
end