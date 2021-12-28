local http, url = ...

function blockexchange.api.get_schemascreenshots(schema_id)
  return Promise.new(function(resolve, reject)
    http.fetch({
      url = url .. "/api/schema/" .. schema_id .. "/screenshot",
      timeout = 5
    }, function(res)
      if res.succeeded and res.code == 200 then
        local data = minetest.parse_json(res.data)
        resolve(data)
      else
        reject(res.code or 0)
      end
    end)
  end)
end

function blockexchange.api.get_schemascreenshot(schema_id, screenshot_id, height, width)
  return Promise.new(function(resolve, reject)
    http.fetch({
      url = url .. "/api/schema/" .. schema_id .. "/screenshot/" .. screenshot_id ..
        "?height=" .. (height or 200) .. "&width=" .. (width or 300),
      timeout = 5
    }, function(res)
      if res.succeeded and res.code == 200 then
        resolve(res.data)
      else
        reject(res.code or 0)
      end
    end)
  end)
end
