require("mineunit")

mineunit("core")
mineunit("player")
mineunit("default/functions")

sourcefile("spec/common")
sourcefile("init")

describe("validate name", function()
	it("validates the names properly", function()
		assert.equal(true, blockexchange.validate_name("my_name"))
		assert.equal(true, blockexchange.validate_name("my_name-"))
		assert.equal(true, blockexchange.validate_name("my_name-123"))
		assert.equal(false, blockexchange.validate_name(""))
		assert.equal(false, blockexchange.validate_name("my_name- s"))
		assert.equal(false, blockexchange.validate_name(" my_name"))
		assert.equal(false, blockexchange.validate_name("my_name "))
		assert.equal(false, blockexchange.validate_name("my_name@"))
		assert.equal(false, blockexchange.validate_name("my_name?"))
		assert.equal(false, blockexchange.validate_name("my_name/"))
		assert.equal(false, blockexchange.validate_name("/my_name"))
	end)
end)