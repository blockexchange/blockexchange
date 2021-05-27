---------
-- api check functions

local cache
local cache_time = 0

local function check_versions(info, success_callback, error_callback)
    if info.api_version_major ~= blockexchange.api_version_major then
        error_callback("unsupported remote version: " .. info.api_version_major ..
            " (local: " .. blockexchange.api_version_major .. ") please update your mod-version")
    else
        success_callback()
    end
end

--- checks for compatible api version
-- @param success_callback called if the api version matches
-- @param error_callback called if the api is not compatible
function blockexchange.check_api_compat(success_callback, error_callback)
    if cache and (os.time() - cache_time) < 300 then
        -- cached and fresher than 5 minutes
        check_versions(cache, success_callback, error_callback)
        return
    end

    blockexchange.api.get_info():next(function(info)
        cache = info
        cache_time = os.time()
        check_versions(cache, success_callback, error_callback)
    end):catch(function(err_code)
        error_callback("could not get api version, code: " .. err_code)
    end)
end