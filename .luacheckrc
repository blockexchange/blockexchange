globals = {
	"blockexchange",
	"worldedit",
	"minetest",
	"nc"
}

max_cyclomatic_complexity = 30

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
	"mtzip", "placeholder", "Promise", "advtrains"
}
