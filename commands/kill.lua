
minetest.register_chatcommand("bx_kill", {
	description = "Kills a blockexchange processes",
	params = "<id>",
	privs = { blockexchange = true },
	func = function(_, id_str)
		local id = tonumber(id_str or "")
		if not id then
			return false, "invalid process id format"
		end

		local new_processes = {}
		local success = false
		for _, ctx in ipairs(blockexchange.processes) do
			-- filter by id
			if ctx._meta.id ~= id then
				table.insert(new_processes, ctx)
			else
				success = true
			end
    end

		blockexchange.processes = new_processes

		if success then
			return true, "Process killed!"
		else
			return false, "Process not found!"
		end
  end
})
