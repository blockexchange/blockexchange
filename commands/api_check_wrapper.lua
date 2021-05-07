
function blockexchange.api_check_wrapper(fn)
    return function(name, param)
        -- check api version
        blockexchange.check_api_compat(function()
            fn(name, param)
        end,
        function(err_msg)
            minetest.chat_send_player(name, minetest.colorize("#ff0000", err_msg))
        end)

        -- handled
        return true
    end
end