
function blockexchange.download(playername, pos1, username, schemaname)
	local ctx = {
		type = "download",
		playername = playername,
		username = username,
		schemaname = schemaname,
		pos1 = pos1,
		current_part = 0,
		progress_percent = 0
	}

	blockexchange.api.get_schema_by_name(username, schemaname, true, function(schema)
		ctx.pos2 = vector.add(pos1, blockexchange.get_schema_size(schema))
		ctx.schema = schema
		-- calculate origin point
		ctx.origin = vector.subtract(ctx.pos1, {
			x = ctx.schema.size_x_minus,
			y = ctx.schema.size_y_minus,
			z = ctx.schema.size_z_minus,
		})
		blockexchange.register_area(ctx.pos1, ctx.pos2, {
			schemaname = schemaname,
			username = username,
			owner = playername
		})
		blockexchange.download_worker(ctx)
	end,
	function()
		minetest.chat_send_player(ctx.playername, "Schema not found: '" ..
			username .. "/" .. schemaname .. "'")
	end)

	return ctx
end
