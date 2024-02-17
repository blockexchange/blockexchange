
-- playername => key
local active_preview = {}

function blockexchange.show_preview(playername, texture, color, pos1, pos2)
	pos2 = pos2 or pos1
	texture = texture .. "^[colorize:" .. color

	pos1, pos2 = blockexchange.sort_pos(pos1, pos2)

	local key =
		minetest.pos_to_string(pos1) .. "/" ..
		minetest.pos_to_string(pos2) .. "/" ..
		texture

	if active_preview[playername] == key then
		-- already active on the same region
		return
	end
	-- clear previous entities
	blockexchange.clear_preview(playername)
	active_preview[playername] = key

	local visual_size = vector.add(vector.subtract(pos2, pos1), 1)
	local offset = vector.divide(vector.subtract(pos2, pos1), 2)
	local origin = vector.subtract(pos2, offset)

	local ent = blockexchange.add_entity(origin, key)
	ent:set_properties({
		visual_size = visual_size,
		textures = {
			texture,
			texture,
			texture,
			texture,
			texture,
			texture
		}
	})
end

function blockexchange.clear_preview(playername)
	if active_preview[playername] then
		blockexchange.remove_entities(active_preview[playername])
		active_preview[playername] = nil
	end
end

minetest.register_on_leaveplayer(function(player)
	blockexchange.clear_preview(player:get_player_name())
end)