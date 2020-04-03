
function blockexchange.allocate(playername, pos1, schema_uid)
  blockexchange.api.get_schema(schema_uid, function(schema)
    local pos2 = vector.add(pos1, {x=schema.size_x, y=schema.size_y, z=schema.size_z})
    pos2 = vector.subtract(pos2, 1)

    local total_parts =
      math.ceil(math.abs(pos1.x - pos2.x) / blockexchange.part_length) *
      math.ceil(math.abs(pos1.y - pos2.y) / blockexchange.part_length) *
      math.ceil(math.abs(pos1.z - pos2.z) / blockexchange.part_length)

    blockexchange.set_pos(2, playername, pos2)
    minetest.chat_send_player(playername, "Total parts: " .. total_parts)
  end)
end
