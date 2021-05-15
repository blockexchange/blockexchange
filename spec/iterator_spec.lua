require("mineunit")

mineunit("core")
mineunit("player")
mineunit("default/functions")

sourcefile("spec/common")
sourcefile("init")

describe("blockexchange.iterator", function()
	it("returns proper positive coordinates", function()
		local origin = { x=0, y=0, z=0 }
		local pos1 = { x=0, y=0, z=0 }
		local pos2 = { x=17, y=0, z=0 }

		local it = blockexchange.iterator(origin, pos1, pos2)
		local pos, abs_pos = it()
		assert.not_nil(pos)
		assert.equals(0, pos.x)
		assert.equals(0, pos.y)
		assert.equals(0, pos.z)

		assert.not_nil(abs_pos)
		assert.equals(0, abs_pos.x)
		assert.equals(0, abs_pos.y)
		assert.equals(0, abs_pos.z)

		pos, abs_pos = it()
		assert.not_nil(pos)
		assert.equals(16, pos.x)
		assert.equals(0, pos.y)
		assert.equals(0, pos.z)

		assert.not_nil(pos)
		assert.equals(16, abs_pos.x)
		assert.equals(0, abs_pos.y)
		assert.equals(0, abs_pos.z)

		pos, abs_pos = it()
		assert.is_nil(pos)
		assert.is_nil(abs_pos)
	end)

	it("returns proper positive coordinates with modified origin", function()
		local origin = { x=10, y=0, z=0 }
		local pos1 = { x=11, y=0, z=0 }
		local pos2 = { x=27, y=0, z=0 }

		local it = blockexchange.iterator(origin, pos1, pos2)
		local pos, abs_pos = it()
		assert.not_nil(pos)
		assert.equals(0, pos.x)
		assert.equals(0, pos.y)
		assert.equals(0, pos.z)

		assert.not_nil(abs_pos)
		assert.equals(10, abs_pos.x)
		assert.equals(0, abs_pos.y)
		assert.equals(0, abs_pos.z)

		pos, abs_pos = it()
		assert.not_nil(pos)
		assert.equals(16, pos.x)
		assert.equals(0, pos.y)
		assert.equals(0, pos.z)

		assert.not_nil(abs_pos)
		assert.equals(26, abs_pos.x)
		assert.equals(0, abs_pos.y)
		assert.equals(0, abs_pos.z)

		pos, abs_pos = it()
		assert.is_nil(pos)
		assert.is_nil(abs_pos)
	end)

	it("returns proper negative coordinates", function()
		local origin = { x=0, y=0, z=0 }
		local pos1 = { x=-5, y=0, z=0 }
		local pos2 = { x=5, y=0, z=0 }

		local it = blockexchange.iterator(origin, pos1, pos2)
		local pos, abs_pos = it()
		assert.not_nil(pos)
		assert.equals(-16, pos.x)
		assert.equals(0, pos.y)
		assert.equals(0, pos.z)

		assert.not_nil(abs_pos)
		assert.equals(-16, abs_pos.x)
		assert.equals(0, abs_pos.y)
		assert.equals(0, abs_pos.z)

		pos, abs_pos = it()
		assert.not_nil(pos)
		assert.equals(0, pos.x)
		assert.equals(0, pos.y)
		assert.equals(0, pos.z)

		assert.not_nil(abs_pos)
		assert.equals(0, abs_pos.x)
		assert.equals(0, abs_pos.y)
		assert.equals(0, abs_pos.z)

		pos, abs_pos = it()
		assert.is_nil(pos)
		assert.is_nil(abs_pos)
	end)

	it("returns proper negative coordinates with modified origin", function()
		local origin = { x=-1, y=0, z=0 }
		local pos1 = { x=-5, y=0, z=0 }
		local pos2 = { x=5, y=0, z=0 }

		local it = blockexchange.iterator(origin, pos1, pos2)
		local pos, abs_pos = it()
		assert.not_nil(pos)
		assert.equals(-16, pos.x)
		assert.equals(0, pos.y)
		assert.equals(0, pos.z)

		assert.not_nil(abs_pos)
		assert.equals(-17, abs_pos.x)
		assert.equals(0, abs_pos.y)
		assert.equals(0, abs_pos.z)

		pos, abs_pos = it()
		assert.not_nil(pos)
		assert.equals(0, pos.x)
		assert.equals(0, pos.y)
		assert.equals(0, pos.z)

		assert.not_nil(abs_pos)
		assert.equals(-1, abs_pos.x)
		assert.equals(0, abs_pos.y)
		assert.equals(0, abs_pos.z)

		pos, abs_pos = it()
		assert.is_nil(pos)
		assert.is_nil(abs_pos)
	end)
end)
