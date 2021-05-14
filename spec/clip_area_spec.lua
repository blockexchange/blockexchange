require("mineunit")

mineunit("core")
mineunit("player")
mineunit("default/functions")

sourcefile("spec/common")
sourcefile("init")

describe("clip_area test", function()
	it("returns the proper coordinates", function()
		local bounds = {
			pos1 = { x=10, y=10, z=10 },
			pos2 = { x=20, y=30, z=40 }
		}

		local area = {
			pos1 = { x=9, y=11, z=20 },
			pos2 = { x=21, y=30, z=40 }
		}

		local clipped_area = blockexchange.clip_area(bounds, area)
		assert.not_nil(clipped_area)
		assert.not_nil(clipped_area.pos1)
		assert.equal(10, clipped_area.pos1.x)
		assert.equal(11, clipped_area.pos1.y)
		assert.equal(20, clipped_area.pos1.z)
		assert.not_nil(clipped_area.pos2)
		assert.equal(20, clipped_area.pos2.x)
		assert.equal(30, clipped_area.pos2.y)
		assert.equal(40, clipped_area.pos2.z)

	end)
end)
