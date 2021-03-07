require("mineunit")

mineunit("core")
mineunit("player")
mineunit("default/functions")

minetest.request_http_api = function()
	return {}
end

sourcefile("init")

describe("blockexchange.sort_pos", function()
	it("returns proper coordinates", function()
		local pos1 = {x=1, y=2, z=3}
		local pos2 = {x=0, y=0, z=0}
		pos1, pos2 = blockexchange.sort_pos(pos1, pos2)
		assert.not_nil(pos1)
		assert.not_nil(pos2)
		assert.equals(0, pos1.x)
	end)
end)
