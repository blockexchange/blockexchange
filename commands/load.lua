
function blockexchange.load(playername, pos1, username, schemaname, local_load)
	local ctx = {
		type = "download",
		local_load = local_load,
		playername = playername,
		username = username,
		schemaname = schemaname,
		pos1 = pos1,
		current_part = 0,
		progress_percent = 0
	}

	if local_load then
		local schema = blockexchange.get_local_schema(schemaname)
		if not schema then
		  minetest.chat_send_player(playername, "Schema not found: '" .. schemaname .. "'")
		  return
		end
		local pos2 = vector.add(pos1, blockexchange.get_schema_size(schema))
		pos2 = vector.subtract(pos2, 1)

		local total_parts =
			math.ceil(math.abs(pos1.x - pos2.x) / blockexchange.part_length) *
			math.ceil(math.abs(pos1.y - pos2.y) / blockexchange.part_length) *
			math.ceil(math.abs(pos1.z - pos2.z) / blockexchange.part_length)

		ctx.pos2 = pos2
		ctx.origin = vector.subtract(ctx.pos1, {
			x = schema.size_x_minus,
			y = schema.size_y_minus,
			z = schema.size_z_minus,
		})

		ctx.schema = {
			total_parts = total_parts
		}

		blockexchange.set_pos(2, playername, pos2)
		blockexchange.load_worker(ctx)
	else
		blockexchange.api.get_schema_by_name(username, schemaname, true):next(function(schema)
			ctx.pos2 = vector.add(pos1, blockexchange.get_schema_size(schema))
			ctx.schema = schema
			-- calculate origin point
			ctx.origin = vector.subtract(ctx.pos1, {
				x = ctx.schema.size_x_minus,
				y = ctx.schema.size_y_minus,
				z = ctx.schema.size_z_minus,
			})
			blockexchange.register_area(ctx.pos1, ctx.pos2, {
				type = "download",
				schemaname = schemaname,
				username = username,
				owner = playername
				-- TODO: mtime to track changes
			})
			blockexchange.load_worker(ctx)
		end):catch(function()
			minetest.chat_send_player(ctx.playername, "Schema not found: '" ..
				username .. "/" .. schemaname .. "'")
		end)
	end

	return ctx
end
