mtt.register("validate name, validates the names properly", function(callback)
	assert(blockexchange.validate_name("my_name"))
	assert(blockexchange.validate_name("my_name-"))
	assert(blockexchange.validate_name("my_name-123"))
	assert(not blockexchange.validate_name(""))
	assert(not blockexchange.validate_name("my_name- s"))
	assert(not blockexchange.validate_name(" my_name"))
	assert(not blockexchange.validate_name("my_name "))
	assert(not blockexchange.validate_name("my_name@"))
	assert(not blockexchange.validate_name("my_name?"))
	assert(not blockexchange.validate_name("my_name/"))
	assert(not blockexchange.validate_name("/my_name"))
	callback()
end)
