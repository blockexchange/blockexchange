
-- id -> true
local active_entities = {}

minetest.register_entity("blockexchange:display", {
	initial_properties = {
		physical = false,
        static_save = false,
		collisionbox = {0, 0, 0, 0, 0, 0},
		visual = "cube",
		backface_culling = false,
		visual_size = {x=1, y=1, z=1},
		glow = 10
	},
	on_step = function(self)
		if not active_entities[self.id] then
			-- not valid anymore
			self.object:remove()
		end
	end
})

function blockexchange.add_entity(pos, id)
	active_entities[id] = true
	local ent = minetest.add_entity(pos, "blockexchange:display")
	local luaent = ent:get_luaentity()
	luaent.id = id
	return ent
end

function blockexchange.remove_entities(id)
	active_entities[id] = nil
end
