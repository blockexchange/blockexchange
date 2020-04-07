-- localize variables to prevent tampering after mod load
local http = blockexchange.http
local url = blockexchange.url

function blockexchange.api.find_schema_by_keywords(keywords, callback, err_callback)
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
      callback(true)
		elseif type(err_callback) == "function" then
      err_callback(res.code or 0)
    end
  end)
end