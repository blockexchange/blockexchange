globals = {
	"blockexchange",
	"worldedit",
	["minetest"] = {
		["request_http_api"] = true
	},
	"AreaStore",
}

read_globals = {
	-- Stdlib
	string = {fields = {"split", "trim"}},
	table = {fields = {"copy", "getn"}},

	-- Minetest
	"minetest",
	"vector", "ItemStack",
	"dump", "dump2",
	"VoxelArea",

	-- opt deps
	"areas", "monitoring",

	-- testing
	"mineunit", "sourcefile", "assert"
}
