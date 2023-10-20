globals = {
	"blockexchange",
	"worldedit",
	"minetest"
}

read_globals = {
	-- Stdlib
	string = {fields = {"split", "trim"}},
	table = {fields = {"copy", "getn"}},

	-- Minetest
	"vector", "ItemStack",
	"dump", "dump2",
	"AreaStore",
	"VoxelArea",

	-- opt deps
	"areas", "monitoring", "mtt", "mapsync",

	-- deps
	"mtzip", "placeholder", "Promise"
}
