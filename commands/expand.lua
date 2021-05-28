---------
-- async expand/update command


--- expands the given area and uploads the newly created real-estate
-- @param playername the playername to use in messages
-- @param area the already existing area
-- @param axis the axis to expand
-- @param nodecount the amount of nodes to add
-- @return a promise that resolves if the operation is complete
function blockexchange.expand(playername, area, axis, nodecount)
    print(playername, axis, nodecount) -- XXX
    local promise = Promise.new()
    -- get and validate schema
    blockexchange.api.get_schema_by_name(area.data.username, area.data.schemaname):next(function(schema)
        print(schema) -- XXX
        -- TODO: compare sizes/origin
    end):catch(function(err)
        promise:reject(err)
    end)
    -- TODO: update schema with new dimensions
    -- TODO: upload new schemaparts

    return promise
end