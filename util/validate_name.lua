---------
-- name validation

--- validate the given name for sane characters
-- @param name the name to validate
function blockexchange.validate_name(name)
    return name ~= "" and string.match(name, "^[a-zA-Z0-9_.-]*$") ~= nil
end