
minetest.register_chatcommand("bx", {
    description = "Shows the blockexchange ui",
    func = function(name)
        blockexchange.ui.main(name)
    end
})