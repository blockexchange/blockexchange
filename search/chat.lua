
minetest.register_chatcommand("bx_search", {
  params = "<keywords>",
	description = "Search for available schemas, for example '/bx_search mesecons'",
	func = function(playername, param)
    if not param or #param == 0 then
      return false, "Usage: /bx_search <keywords>"
    end

    blockexchange.api.find_schema_by_keywords(param, function(schemas)
      if not schemas or #schemas == 0 then
        minetest.chat_send_player(playername, "No schemas found!")
        return
      end

      blockexchange.show_search_result_formspec(playername, schemas)
    end,
    function(http_code)
      minetest.chat_send_player(playername, "Query failed, http-status: " .. (http_code or "<none>"))
    end)
		return true, "Searching for: '" .. param .. "'"
	end
})