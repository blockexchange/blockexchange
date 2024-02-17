
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
			local token = blockexchange.get_token(name)
			if not token then
				-- not logged in
				return false, "Not logged in, usage: /bx_login <username> <access_token>"
			end

			-- logged in, show status
			local payload = blockexchange.parse_token(token)
			if not payload or not payload.user_uid then
				-- invalid or old token
				-- TODO: check validity
				return false, "Not logged in, token invalid or expired"
			end

			return true, "Logged in as '" .. payload.username .. "' with user_uid: " .. payload.user_uid
		end

		blockexchange.api.get_token(username, access_token):next(function(token)
			blockexchange.set_token(name, token)
			local payload = blockexchange.parse_token(token)
			minetest.chat_send_player(name, "Logged in as '" .. payload.username .. "' with user_uid: " .. payload.user_uid)
		end):catch(function(http_code)
			minetest.log("error", "[blockexchange] get_token failed with error: " .. http_code or "?")
			minetest.chat_send_player(name, "Login failed with error: " .. http_code or "?")
		end)
  end
})

minetest.register_chatcommand("bx_logout", {
	description = "Logs the current user out",
	func = function(name)
		blockexchange.set_token(name)
		minetest.chat_send_player(name, "Logged out successfully")
  end
})
