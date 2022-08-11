mtt.register("blockexchange.sort_pos, returns proper coordinates", function(callback)
	local pos1 = {x=1, y=2, z=3}
	local pos2 = {x=0, y=0, z=0}
	pos1, pos2 = blockexchange.sort_pos(pos1, pos2)
	assert(pos1)
	assert(pos2)
	assert(0 == pos1.x)
	assert(0 == pos1.y)
	assert(0 == pos1.z)
	assert(1 == pos2.x)
	assert(2 == pos2.y)
	assert(3 == pos2.z)
	callback()
end)
