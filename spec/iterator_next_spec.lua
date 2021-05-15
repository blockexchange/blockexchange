require("mineunit")

mineunit("core")
mineunit("player")
mineunit("default/functions")

sourcefile("spec/common")
sourcefile("init")

describe("blockexchange.iterator_next", function()
	it("returns proper coordinates", function()
		local pos1 = { x=0, y=0, z=0 }
		local pos2 = { x=129, y=0, z=0 }
		local current_pos
		local expected_x_pos_list = {0, 16, 32, 48, 64, 80, 96, 112, 128}

		for _, expected_x in ipairs(expected_x_pos_list) do
			current_pos = blockexchange.iterator_next(pos1, pos2, current_pos)
			assert.not_nil(current_pos)
			assert.equals(expected_x, current_pos.x)
		end

	end)
end)
