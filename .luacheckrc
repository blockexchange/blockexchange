globals = {
	"blockexchange",
	"worldedit",
	"Promise",
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
	"areas", "monitoring", "mtt"
}
