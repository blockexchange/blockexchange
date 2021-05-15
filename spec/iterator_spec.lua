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
		local pos = it()
		assert.not_nil(pos)
		assert.equals(0, pos.x)
		assert.equals(0, pos.y)
		assert.equals(0, pos.z)

		pos = it()
		assert.not_nil(pos)
		assert.equals(16, pos.x)
		assert.equals(0, pos.y)
		assert.equals(0, pos.z)

		pos = it()
		assert.is_nil(pos)
	end)

	it("returns proper positive coordinates with modified origin", function()
		local origin = { x=10, y=0, z=0 }
		local pos1 = { x=11, y=0, z=0 }
		local pos2 = { x=27, y=0, z=0 }

		local it = blockexchange.iterator(origin, pos1, pos2)
		local pos = it()
		assert.not_nil(pos)
		assert.equals(0, pos.x)
		assert.equals(0, pos.y)
		assert.equals(0, pos.z)

		pos = it()
		assert.not_nil(pos)
		assert.equals(16, pos.x)
		assert.equals(0, pos.y)
		assert.equals(0, pos.z)

		pos = it()
		assert.is_nil(pos)
	end)

	it("returns proper negative coordinates", function()
		local origin = { x=0, y=0, z=0 }
		local pos1 = { x=-5, y=0, z=0 }
		local pos2 = { x=5, y=0, z=0 }

		local it = blockexchange.iterator(origin, pos1, pos2)
		local pos = it()
		assert.not_nil(pos)
		assert.equals(-16, pos.x)
		assert.equals(0, pos.y)
		assert.equals(0, pos.z)

		pos = it()
		assert.not_nil(pos)
		assert.equals(0, pos.x)
		assert.equals(0, pos.y)
		assert.equals(0, pos.z)

		pos = it()
		assert.is_nil(pos)
	end)
end)
