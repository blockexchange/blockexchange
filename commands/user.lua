
minetest.register_chatcommand("bx_login", {
	params = "<username> <access_token>",
	description = "Login with an existing user and access_token or check the current login",
	func = function(name, param)
		if not minetest.check_player_privs(name, { blockexchange = true }) and
			not minetest.check_player_privs(name, { blockexchange_protected_upload = true }) then
				return false, "Required privs: 'blockexchange' or 'blockexchange_protected_upload'"
		end

		local _, _, username, access_token = string.find(param, "^([^%s]+)%s+([^%s]+)%s*$")
		if not username or not access_token then
			local player_settings = blockexchange.get_player_settings(name)
			if not player_settings.token then
				-- not logged in
				return false, "Not logged in, usage: /bx_login <username> <access_token>"
			end

			-- logged in, show status
			local payload = blockexchange.parse_token(player_settings.token)
			if not payload or not payload.user_uid then
				-- invalid or old token
				-- TODO: check validity
				return false, "Not logged in, token invalid or expired"
			end

			return true, "Logged in as '" .. payload.username .. "' with user_uid: " .. payload.user_uid
		end

		blockexchange.api.get_token(username, access_token):next(function(token)
			local player_settings = blockexchange.get_player_settings(name)
			player_settings.token = token
			blockexchange.set_player_settings(name, player_settings)

			local payload = blockexchange.parse_token(token)
			minetest.chat_send_player(name, "Logged in as '" .. payload.username .. "' with user_uid: " .. payload.user_uid)
		end):catch(function(err)
			minetest.log("error", "[blockexchange] get_token failed: " .. err or "?")
			minetest.chat_send_player(name, "Login failed: " .. err or "?")
		end)
  end
})

minetest.register_chatcommand("bx_logout", {
	description = "Logs the current user out",
	func = function(name)
		local player_settings = blockexchange.get_player_settings(name)
		player_settings.token = nil
		blockexchange.set_player_settings(name, player_settings)
		minetest.chat_send_player(name, "Logged out successfully")
  end
})
