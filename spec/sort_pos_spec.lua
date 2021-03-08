require("mineunit")

mineunit("core")
mineunit("player")
mineunit("default/functions")

sourcefile("spec/common")
sourcefile("init")

describe("blockexchange.sort_pos", function()
	it("returns proper coordinates", function()
		local pos1 = {x=1, y=2, z=3}
		local pos2 = {x=0, y=0, z=0}
		pos1, pos2 = blockexchange.sort_pos(pos1, pos2)
		assert.not_nil(pos1)
		assert.not_nil(pos2)
		assert.equals(0, pos1.x)
		assert.equals(0, pos1.y)
		assert.equals(0, pos1.z)
		assert.equals(1, pos2.x)
		assert.equals(2, pos2.y)
		assert.equals(3, pos2.z)
	end)
end)
