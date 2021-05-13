local Promise = require("../util/promise")

describe("promise test", function()
	it("simple smoke test", function()
        assert.not_nil(Promise)

		local p = Promise.new(function(resolve)
			resolve(1)
		end)

		local result

		p:next(function(v)
			return Promise.new(function(resolve)
				resolve(v + 1)
			end)
		end):next(function(v)
			result = v
		end)

		Promise.update()

		assert.equal(2, result)
	end)
end)
