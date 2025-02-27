
local token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9" ..
    ".eyJleHAiOjEwODkzMTAyODEzLCJ1c2VybmFtZSI6IlRlc3R1c2Vy" ..
    "IiwidXNlcl9pZCI6MSwibWFpbCI6IiIsInR5cGUiOiJMT0NBTCIsI" ..
    "nBlcm1pc3Npb25zIjpbIlVQTE9BRCIsIk9WRVJXUklURSJdfQ.BpA" ..
    "D1In8-zLRPsNqHkNVuuPiDM92WPDrcV_0wUvWXOQ"

mtt.register("token", function(callback)
    local playername = "singleplayer"
    local player_settings = blockexchange.get_player_settings(playername)
    player_settings.token = token
    blockexchange.set_player_settings(playername, player_settings)

    local claims = assert(blockexchange.get_claims(playername))

    assert(claims.username == "Testuser")
    assert(claims.exp == 10893102813)

    local current_time = 1669731078 -- os.time()
    assert(blockexchange.check_expiration(current_time, claims))

    callback()
end)