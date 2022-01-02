local FORMNAME = "blockexchange_controller"

function blockexchange.ui.show_controller_main(pos, playername)
	local autosave = blockexchange.get_autosave(pos)
	local meta = minetest.get_meta(pos)
	local schema = minetest.deserialize(meta:get_string("schema"))
	local claims = blockexchange.get_claims(playername)

	local is_privileged = schema.user_id == claims.user_id

	-- autosave part
	local autosave_form = "button_exit[0,2.5;7,1;"
	-- check if toggled
	if autosave then
		autosave_form = autosave_form .. "disable_autosave;Disable autosave"
	else
		autosave_form = autosave_form .. "enable_autosave;Enable autosave"
	end
	autosave_form = autosave_form .. "]"
	autosave_form = autosave_form .. "button_exit[0,3.5;7,1;upload;Upload everything]"

	-- assemble privileged (write-operations) part of the formspec
	local privileged_formspec = autosave_form

	-- assemble whole formspec galore
	local formspec = "size[8,6;]" ..
		"label[0,0;Blockexchange controller]" ..
		(is_privileged and privileged_formspec or "") ..
		"button_exit[0,4.5;7,1;mark;Mark area]" ..
		"button_exit[0,5.5;7,1;quit;Exit]" ..
		""

	minetest.show_formspec(playername, FORMNAME .. ";" .. minetest.pos_to_string(pos), formspec)
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	local parts = formname:split(";")
	local name = parts[1]
	if name ~= FORMNAME or not minetest.check_player_privs(player, "blockexchange") then
		return
	end

	local pos = minetest.string_to_pos(parts[2])
	local playername = player:get_player_name()
	local job_active = blockexchange.get_job_context(playername)

	if minetest.is_protected(pos, playername) then
		return
	end

	if fields.enable_autosave then
		if job_active then
			minetest.chat_send_player(playername, "Can't enable autosave, a job is already active")
		else
			blockexchange.enable_autosave(pos)
		end
	end

	if fields.disable_autosave then
		blockexchange.disable_autosave(pos)
	end

	if fields.upload then
		-- full upload
		if job_active then
			minetest.chat_send_player(playername, "Can't upload, a job is already active")
			return
		end

		local meta = minetest.get_meta(pos)
		local origin = minetest.deserialize(meta:get_string("origin"))
		local schema = minetest.deserialize(meta:get_string("schema"))
		local pos2 = vector.add(origin, vector.subtract({ x=schema.size_x, y=schema.size_y, z=schema.size_z }, 1))

		-- TODO: verify user
		local claims = blockexchange.get_claims(playername)

		local promise, ctx = blockexchange.save_update(playername, origin, origin, pos2, claims.username, schema.id)
		blockexchange.set_job_context(playername, ctx)

		promise:next(function()
			blockexchange.set_job_context(playername, nil)

		end):catch(function(err_msg)
			blockexchange.set_job_context(playername, nil)
			minetest.chat_send_player(playername, minetest.colorize("#ff0000", err_msg))
		end)

	end

	if fields.mark then
		local meta = minetest.get_meta(pos)
		local origin = minetest.deserialize(meta:get_string("origin"))
		local schema = minetest.deserialize(meta:get_string("schema"))

		local pos2 = vector.add(origin, vector.subtract({ x=schema.size_x, y=schema.size_y, z=schema.size_z }, 1))
		blockexchange.set_pos(1, playername, origin)
		blockexchange.set_pos(2, playername, pos2)
	end
end)
