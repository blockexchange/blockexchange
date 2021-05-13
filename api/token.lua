local http, url = ...

function blockexchange.api.get_token(name, access_token)
  return Promise.new(function(resolve, reject)
    local json = minetest.write_json({
      name = name,
      access_token = access_token
    });

    http.fetch({
      url = url .. "/api/token",
      extra_headers = { "Content-Type: application/json" },
      timeout = 5,
      post_data = json
    }, function(res)
      if res.succeeded and res.code == 200 then
        resolve(res.data)
      else
        reject(res.code or 0)
      end
    end)
  end)
end
