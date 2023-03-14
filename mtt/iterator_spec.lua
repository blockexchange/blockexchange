mtt.register("blockexchange.iterator, smoke tests", function(callback)
	local origin = { x=0, y=0, z=0 }
	local pos1 = { x=0, y=0, z=0 }
	local pos2 = { x=17, y=0, z=0 }

	local last_progress = 0
	for abs_pos, pos, progress in blockexchange.iterator(origin, pos1, pos2) do
		assert(abs_pos and abs_pos.x)
		assert(pos and pos.x)
		assert(progress >= last_progress)
		last_progress = progress
	end

	callback()
end)

mtt.register("blockexchange.iterator, returns proper positive coordinates", function(callback)
	local origin = { x=0, y=0, z=0 }
	local pos1 = { x=0, y=0, z=0 }
	local pos2 = { x=17, y=0, z=0 }

	local it = blockexchange.iterator(origin, pos1, pos2)
	local abs_pos, pos, progress = it()
	assert(pos)
	assert(0 == pos.x)
	assert(0 == pos.y)
	assert(0 == pos.z)
	assert(0.5 == progress)

	assert(abs_pos)
	assert(0 == abs_pos.x)
	assert(0 == abs_pos.y)
	assert(0 == abs_pos.z)

	abs_pos, pos, progress = it()
	assert(pos)
	assert(16 == pos.x)
	assert(0 == pos.y)
	assert(0 == pos.z)
	assert(1 == progress)

	assert(pos)
	assert(16 == abs_pos.x)
	assert(0 == abs_pos.y)
	assert(0 == abs_pos.z)

	abs_pos, pos = it()
	assert(not pos)
	assert(not abs_pos)
	callback()
end)

mtt.register("blockexchange.iterator, returns proper positive coordinates with modified origin", function(callback)
	local origin = { x=10, y=0, z=0 }
	local pos1 = { x=11, y=0, z=0 }
	local pos2 = { x=27, y=0, z=0 }

	local it = blockexchange.iterator(origin, pos1, pos2)
	local abs_pos, pos = it()
	assert(pos)
	assert(0 == pos.x)
	assert(0 == pos.y)
	assert(0 == pos.z)

	assert(abs_pos)
	assert(10 == abs_pos.x)
	assert(0 == abs_pos.y)
	assert(0 == abs_pos.z)

	abs_pos, pos = it()
	assert(pos)
	assert(16 == pos.x)
	assert(0 == pos.y)
	assert(0 == pos.z)

	assert(abs_pos)
	assert(26 == abs_pos.x)
	assert(0 == abs_pos.y)
	assert(0 == abs_pos.z)

	abs_pos, pos = it()
	assert(not pos)
	assert(not abs_pos)
	callback()
end)

mtt.register("blockexchange.iterator, returns proper negative coordinates", function(callback)
	local origin = { x=0, y=0, z=0 }
	local pos1 = { x=-5, y=0, z=0 }
	local pos2 = { x=5, y=0, z=0 }

	local it = blockexchange.iterator(origin, pos1, pos2)
	local abs_pos, pos = it()
	assert(pos)
	assert(-16 == pos.x)
	assert(0 == pos.y)
	assert(0 == pos.z)

	assert(abs_pos)
	assert(-16 == abs_pos.x)
	assert(0 == abs_pos.y)
	assert(0 == abs_pos.z)

	abs_pos, pos = it()
	assert(pos)
	assert(0 == pos.x)
	assert(0 == pos.y)
	assert(0 == pos.z)

	assert(abs_pos)
	assert(0 == abs_pos.x)
	assert(0 == abs_pos.y)
	assert(0 == abs_pos.z)

	abs_pos, pos = it()
	assert(not pos)
	assert(not abs_pos)
	callback()
end)

mtt.register("blockexchange.iterator, returns proper negative coordinates with modified origin", function(callback)
	local origin = { x=-1, y=0, z=0 }
	local pos1 = { x=-5, y=0, z=0 }
	local pos2 = { x=5, y=0, z=0 }

	local it = blockexchange.iterator(origin, pos1, pos2)
	local abs_pos, pos = it()
	assert(pos)
	assert(-16 == pos.x)
	assert(0 == pos.y)
	assert(0 == pos.z)

	assert(abs_pos)
	assert(-17 == abs_pos.x)
	assert(0 == abs_pos.y)
	assert(0 == abs_pos.z)

	abs_pos, pos = it()
	assert(pos)
	assert(0 == pos.x)
	assert(0 == pos.y)
	assert(0 == pos.z)

	assert(abs_pos)
	assert(-1 == abs_pos.x)
	assert(0 == abs_pos.y)
	assert(0 == abs_pos.z)

	abs_pos, pos = it()
	assert(not pos)
	assert(not abs_pos)
	callback()
end)
