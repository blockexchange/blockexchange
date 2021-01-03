
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
			if not blockexchange.tokens[name] then
				-- not logged in
				return false, "Usage: /bx_login <username> <access_token>"
			end

			-- logged in, show status
			local payload = blockexchange.parse_token(blockexchange.tokens[name])
			-- TODO: check validity
			return true, "Logged in as '" .. payload.username .. "' with user_id: " .. payload.user_id
		end

		blockexchange.api.get_token(username, access_token, function(token)
			blockexchange.tokens[name] = token
			blockexchange.persist_tokens()
			minetest.chat_send_player(name, "Logged in successfully")
		end,
		function(http_code)
			minetest.log("error", "[blockexchange] get_token failed with error: " .. http_code or "?")
			minetest.chat_send_player(name, "Login failed with error: " .. http_code or "?")
		end)
  end
})

minetest.register_chatcommand("bx_logout", {
	description = "Logs the current user out",
	func = function(name)
		blockexchange.tokens[name] = nil
		blockexchange.persist_tokens()
		minetest.chat_send_player(name, "Logged out successfully")
  end
})
