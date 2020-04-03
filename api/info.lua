
-- localize variables to prevent tampering after mod load
local http = blockexchange.http
local url = blockexchange.url

function blockexchange.api.get_info(callback, err_callback)
  http.fetch({
    url = url .. "/api/info",
    timeout = 5
  }, function(res)
    if res.succeeded and res.code == 200 then
      local schema = minetest.parse_json(res.data)
      callback(schema)
    elseif type(err_callback) == "function" then
      err_callback(res.code or 0)
    end
  end)
end
