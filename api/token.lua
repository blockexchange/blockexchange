---------
-- token api calls

local http, url = ...

--- exchanges an acces_token with a jwt token (for authorized http calls)
-- @param name the username
-- @param access_token the access code of the token (used in "/bx_login <username> <access_token>")
-- @return a promise with the result
function blockexchange.api.get_token(name, access_token)
  return Promise.http(http, url .. "/api/token", {
    extra_headers = { "Content-Type: application/json" },
    method = "POST",
    data = minetest.write_json({
      name = name,
      access_token = access_token
    })
  }):next(function(res)
    if res.code == 200 then
      return res:text()
    else
      return Promise.rejected("unexpected http code: " .. res.code)
    end
  end)
end
