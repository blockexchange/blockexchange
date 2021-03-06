local http, url = ...

function blockexchange.api.create_schemapart(token, data)
  return Promise.new(function(resolve, reject)
    http.fetch({
      url = url .. "/api/schemapart",
      extra_headers = {
        "Content-Type: application/json",
        "Authorization: " .. token
      },
      timeout = 5,
      method = "POST",
      post_data = minetest.write_json(data),
    }, function(res)
      if res.succeeded and res.code == 200 then
        resolve(true)
      else
        reject(res.code or 0)
      end
    end)
  end)
end

function blockexchange.api.remove_schemapart(token, schema_id, pos)
  return Promise.new(function(resolve, reject)
    http.fetch({
      url = url .. "/api/schemapart/" .. schema_id .. "/" .. pos.x .. "/" .. pos.y .. "/" .. pos.z,
      extra_headers = {
        "Content-Type: application/json",
        "Authorization: " .. token
      },
      timeout = 5,
      method = "DELETE"
    }, function(res)
      if res.succeeded and res.code == 200 then
        resolve(true)
      else
        reject(res.code or 0)
      end
    end)
  end)
end

function blockexchange.api.get_schemapart(schema_id, pos)
  return Promise.new(function(resolve, reject)
    http.fetch({
      url = url .. "/api/schemapart/" .. schema_id .. "/" .. pos.x .. "/" .. pos.y .. "/" .. pos.z,
      timeout = 5
    }, function(res)
      if res.succeeded and res.code == 200 then
        -- schema part found
        local schemapart = minetest.parse_json(res.data)
        resolve(schemapart)
      elseif (res.succeeded and res.code == 204) or (res.code == 404) then
        -- air only part
        resolve(false)
      else
        reject(res.code or 0)
      end
    end)
  end)
end

function blockexchange.api.get_schemapart_chunk(schema_id, pos)
  return Promise.new(function(resolve, reject)
    http.fetch({
      url = url .. "/api/schemapart_chunk/" .. schema_id .. "/" .. pos.x .. "/" .. pos.y .. "/" .. pos.z,
      timeout = 5
    }, function(res)
      if res.succeeded and res.code == 200 then
        -- schema part found
        local schemaparts = minetest.parse_json(res.data)
        resolve(schemaparts)
      elseif (res.succeeded and res.code == 204) or (res.code == 404) then
        -- air only part
        resolve(false)
      else
        reject(res.code or 0)
      end
    end)
  end)
end

function blockexchange.api.get_first_schemapart(schema_id)
  return Promise.new(function(resolve, reject)
    http.fetch({
      url = url .. "/api/schemapart_first/" .. schema_id,
      timeout = 5
    }, function(res)
      if res.succeeded and res.code == 200 then
        -- schema part found
        local schemapart = minetest.parse_json(res.data)
        resolve(schemapart)
      elseif (res.succeeded and res.code == 204) or (res.code == 404) then
        -- air only part
        resolve(false)
      else
        reject(res.code or 0)
      end
    end)
  end)
end

function blockexchange.api.get_next_schemapart(schema_id, pos)
  return Promise.new(function(resolve, reject)
    http.fetch({
      url = url .. "/api/schemapart_next/" .. schema_id .. "/" .. pos.x .. "/" .. pos.y .. "/" .. pos.z,
      timeout = 5
    }, function(res)
      if res.succeeded and res.code == 200 then
        -- schema part found
        local schemapart = minetest.parse_json(res.data)
        resolve(schemapart)
      elseif (res.succeeded and res.code == 204) or (res.code == 404) then
        -- air only part
        resolve(false)
      else
        reject(res.code or 0)
      end
    end)
  end)
end
