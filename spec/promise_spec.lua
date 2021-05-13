local Promise = require("../util/promise")

describe("promise test", function()
	it("simple smoke test", function()
        assert.not_nil(Promise)

		local p = Promise.new(function(resolve)
			resolve(1)
		end)

		p:next(function(v)
			assert.equal(3, v)
			return Promise.new(function(resolve)
				resolve(v + 1)
			end)
		end):catch(function(e)
			error(e)
		end):next(function(v)
			print(v)
			assert.equal(3, v)
		end):catch(function(e)
			error(e)
		end)

		Promise.update()

	end)
end)
