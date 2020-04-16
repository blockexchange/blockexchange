
-- hud mappings
local pos1_player_map = {}
local pos2_player_map = {}

if minetest.get_modpath("worldedit") then
  -- use WE's positions
  blockexchange.pos1 = worldedit.pos1
  blockexchange.pos2 = worldedit.pos2
end

function blockexchange.set_pos(index, playername, pos)
  if minetest.get_modpath("worldedit") then
    -- worldedit available, use its markers
    if index == 1 then
      worldedit.pos1[playername] = pos
      worldedit.mark_pos1(playername);
    elseif index == 2 then
      worldedit.pos2[playername] = pos
      worldedit.mark_pos2(playername);
    end

    return
  end

  local player = minetest.get_player_by_name(playername)
  if player then
    local map = blockexchange.pos1
    local hud_map = pos1_player_map
    if index == 2 then
      map = blockexchange.pos2
      hud_map = pos2_player_map
    end

    local pos_str = minetest.pos_to_string(pos)
    minetest.chat_send_player(playername, "Position " .. index .. " set to " .. pos_str)
    map[playername] = pos

    if hud_map[playername] then
      player:hud_remove(hud_map[playername])
    end

    hud_map[playername] = player:hud_add({
      hud_elem_type = "waypoint",
      name = "Position " .. index .. " @ " .. pos_str,
      text = "m",
      number = 0xFF0000,
      world_pos = pos
    })
  end
end

-- cleanup
minetest.register_on_leaveplayer(function(player)
	local playername = player:get_player_name()
	pos1_player_map[playername] = nil
	pos2_player_map[playername] = nil
end)


if minetest.get_modpath("worldedit") then
  -- redirect to WE's chat position commands
  minetest.register_chatcommand("bx_pos1", minetest.registered_chatcommands["/pos1"])
  minetest.register_chatcommand("bx_pos2", minetest.registered_chatcommands["/pos2"])
else
  -- use own commands
  minetest.register_chatcommand("bx_pos1", {
    description = "Set position 1",
    privs = { blockexchange = true },
    func = function(name)
      local player = minetest.get_player_by_name(name)
      if player then
        local pos = vector.round(player:get_pos())
        blockexchange.set_pos(1, name, pos)
      end
    end
  })

  minetest.register_chatcommand("bx_pos2", {
    description = "Set position 2",
    privs = { blockexchange = true },
    func = function(name)
      local player = minetest.get_player_by_name(name)
      if player then
        local pos = vector.round(player:get_pos())
        blockexchange.set_pos(2, name, pos)
      end
    end
  })
end
