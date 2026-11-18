
function blockexchange.get_schema_size(schema)
    return {
        x = schema.size_x,
        y = schema.size_y,
        z = schema.size_z
    }
end

-- returns the upper (inclusive) position of a schema placed at pos1
function blockexchange.get_schema_pos2(pos1, schema)
    return vector.subtract(vector.add(pos1, blockexchange.get_schema_size(schema)), 1)
end
