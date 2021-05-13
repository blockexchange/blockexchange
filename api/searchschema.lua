local http, url = ...

function blockexchange.api.find_schema_by_keywords(keywords)
  return Promise.new(function(resolve, reject)
    local json = minetest.write_json({
      keywords = keywords
    });

    http.fetch({
      url = url .. "/api/searchschema",
      extra_headers = {
        "Content-Type: application/json"
      },
      timeout = 5,
      post_data = json
    }, function(res)
      if res.succeeded and res.code == 200 then
        local result = minetest.parse_json(res.data)
        resolve(result)
      else
        reject(res.code or 0)
      end
    end)
  end)
end
