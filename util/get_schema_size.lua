
function blockexchange.get_schema_size(schema)
    return {
        x = schema.size_x_plus + schema.size_x_minus,
        y = schema.size_y_plus + schema.size_y_minus,
        z = schema.size_z_plus + schema.size_z_minus
    }
end