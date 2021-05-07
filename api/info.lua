local http, url = ...

function blockexchange.api.get_info(callback, err_callback)
  http.fetch({
    url = url .. "/api/info",
    timeout = 5
  }, function(res)
    if res.succeeded and res.code == 200 then
      local info = minetest.parse_json(res.data)
      callback(info)
    elseif type(err_callback) == "function" then
      err_callback(res.code or 0)
    end
  end)
end
