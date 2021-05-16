require("mineunit")

mineunit("core")
mineunit("player")
mineunit("default/functions")

sourcefile("spec/common")
sourcefile("init")

describe("clip_area test", function()
	it("returns the proper coordinates", function()
		local clip_pos1 = { x=10, y=10, z=10 }
		local clip_pos2 = { x=20, y=30, z=40 }
		local pos1 = { x=9, y=11, z=20 }
		local pos2 = { x=21, y=30, z=40 }

		local clipped_pos1, clipped_pos2 = blockexchange.clip_area(clip_pos1, clip_pos2, pos1, pos2)
		assert.equal(10, clipped_pos1.x)
		assert.equal(11, clipped_pos1.y)
		assert.equal(20, clipped_pos1.z)
		assert.equal(20, clipped_pos2.x)
		assert.equal(30, clipped_pos2.y)
		assert.equal(40, clipped_pos2.z)
	end)
end)
