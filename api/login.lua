---------
-- login api calls

local http, url = ...

function blockexchange.api.get_claims(token)
  return Promise.http(http, url .. "/api/login", {
    method = "GET",
    headers = {
      "Authorization: " .. token
    }
  }):next(function(res)
    if res.code == 200 then
      -- valid token
      return res:json()
    elseif res.code == 401 then
      -- invalid token
      return false
    else
      return Promise.rejected("unexpected http code: " .. res.code)
    end
  end)
end
