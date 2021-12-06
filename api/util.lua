---------
-- api utilities

local http, url = ...

function blockexchange.api.json(opts)
    return Promise.new(function(resolve, reject)
        local extra_headers = {
            "Content-Type: application/json"
        }

        if opts.token then
            table.insert(extra_headers, "Authorization: " .. opts.token)
        end

        http.fetch({
            url = url .. "/api/" .. opts.endpoint,
            extra_headers = extra_headers,
            timeout = opts.timeout or 10,
            method = opts.method or "GET",
            data = opts.data and minetest.write_json(opts.data)
        }, function(res)
            if res.succeeded and res.code == 200 then
                local obj = minetest.parse_json(res.data)
                resolve(obj)
            else
                local obj
                if res.data and res.data ~= "" then
                    -- TODO: data is empty if the status-code is 400 :/
                    obj = minetest.parse_json(res.data)
                end
                reject(res.code or 0, obj)
            end
        end)
    end)
end