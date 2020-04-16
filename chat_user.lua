

minetest.register_chatcommand("bx_register", {
	params = "<username> <password> [<mail>]",
	description = "Register and login as a new user",
	privs = { blockexchange = true },
	func = function(name, param)

		local _, _, username, password, mail = string.find(param, "^([^%s]+)%s+([^%s]+)%s+([^%s]+)%s*$")
		if not username or not password or not mail then
			_, _, username, password = string.find(param, "^([^%s]+)%s+([^%s]+)%s*$")
		end

		if not username or not password then
			return false, "Usage: /bx_register <username> <password> [<mail>]"
		end

		blockexchange.api.register(username, password, mail, function(result)
			if not result.success then
				minetest.chat_send_player(name, "Register failed with error: " .. result.message or "?")
				return
			end

			blockexchange.api.get_token(username, password, function(token)
				blockexchange.tokens[name] = token
				blockexchange.persist_tokens()
				minetest.chat_send_player(name, "Registered and Logged in successfully")
			end,
			function(http_code)
				minetest.log("error", "[blockexchange] get_token failed with error: " .. http_code or "?")
				minetest.chat_send_player(name, "Login failed with error: " .. http_code or "?")
			end)

		end,
		function(http_code)
			minetest.log("error", "[blockexchange] register failed with error: " .. http_code or "?")
			minetest.chat_send_player(name, "Register failed with error: " .. http_code or "?")
		end)
  end
})

minetest.register_chatcommand("bx_login", {
	params = "<username> <password>",
	description = "Login with an existing user and password or check the current login",
	privs = { blockexchange = true },
	func = function(name, param)
		local _, _, username, password = string.find(param, "^([^%s]+)%s+([^%s]+)%s*$")
		if not username or not password then
			if not blockexchange.tokens[name] then
				-- not logged in
				return false, "Usage: /bx_login <username> <password>"
			end

			-- logged in, show status
			local payload = blockexchange.parse_token(blockexchange.tokens[name])
			-- TODO: check validity
			return true, "Logged in as '" .. payload.username .. "' with user_id: " .. payload.user_id
		end

		blockexchange.api.get_token(username, password, function(token)
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


minetest.register_chatcommand("bx_login_temp", {
	description = "Login with a temporary user",
	privs = { blockexchange = true },
	func = function(name)
		blockexchange.api.get_token("temp", "temp", function(token)
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
	privs = { blockexchange = true },
	func = function(name)
		blockexchange.tokens[name] = nil
		blockexchange.persist_tokens()
		minetest.chat_send_player(name, "Logged out successfully")
  end
})
