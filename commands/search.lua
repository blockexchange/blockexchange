
minetest.register_chatcommand("bx_search", {
  privs = { blockexchange = true },
  description = "Search for available schemas",
  func = function(playername)
    blockexchange.ui.search(playername)
  end
})
