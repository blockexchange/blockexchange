globals = {
	"blockexchange",
	"worldedit",
	["minetest"] = {
		["request_http_api"] = true
	}
}

read_globals = {
	-- Stdlib
	string = {fields = {"split", "trim"}},
	table = {fields = {"copy", "getn"}},

	-- Minetest
	"minetest",
	"vector", "ItemStack",
	"dump", "dump2",
	"VoxelArea", "AreaStore",

	-- opt deps
	"areas", "monitoring",

	-- testing
	"mineunit", "sourcefile", "assert"
}
