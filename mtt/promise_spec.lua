
mtt.register("promise test, smoke test", function(callback)
	assert(Promise)

	local p = Promise.new(function(resolve)
		resolve(1)
	end)

	p:next(function(v)
		return Promise.new(function(resolve)
			resolve(v + 1)
		end)
	end):next(function(v)
		assert(v == 2)
		callback()
	end)
end)


mtt.register("promise test, bool value test", function(callback)
	local p = Promise.new(function(resolve)
		resolve(false)
	end)

	p:next(function(v)
		assert(not v)
		callback()
	end)
end)
