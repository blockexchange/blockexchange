

mtt.register("clip_area test", function(callback)
	local clip_pos1 = { x=10, y=10, z=10 }
	local clip_pos2 = { x=20, y=30, z=40 }
	local pos1 = { x=9, y=11, z=20 }
	local pos2 = { x=21, y=30, z=40 }

	local clipped_pos1, clipped_pos2 = blockexchange.clip_area(clip_pos1, clip_pos2, pos1, pos2)
	assert(10 == clipped_pos1.x)
	assert(11 == clipped_pos1.y)
	assert(20 == clipped_pos1.z)
	assert(20 == clipped_pos2.x)
	assert(30 == clipped_pos2.y)
	assert(40 == clipped_pos2.z)

	callback()
end)
