-- localize variables to prevent tampering after mod load
local http = blockexchange.http
local url = blockexchange.url

function blockexchange.api.register(name, password, mail, callback, err_callback)
  local json = minetest.write_json({
    name = name,
    password = password,
    mail = mail
  });

  http.fetch({
    url = url .. "/api/register",
    extra_headers = { "Content-Type: application/json" },
    timeout = 5,
    post_data = json
  }, function(res)
    if res.succeeded and res.code == 200 then
      local schema = minetest.parse_json(res.data)
      callback(schema)
    elseif type(err_callback) == "function" then
      err_callback(res.code or 0)
    end
  end)
end
