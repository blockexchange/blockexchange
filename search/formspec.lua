local FORMNAME = "blockexchange_search_results"

-- playername -> {}
local search_results = {}

-- playername = <item>
local selected_item_data = {}

function blockexchange.show_search_result_formspec(playername, schemas)
  local list = ""
  local player = minetest.get_player_by_name(playername)

  if not player then
    return
  end

  -- store as last result
  search_results[playername] = schemas

  -- render list items
  for _, schema in ipairs(schemas) do

    local size = (schema.max_x+1) .. " / " ..
      (schema.max_y+1) .. " / " ..
      (schema.max_z+1)

    list = list .. "," ..
      schema.user.name .. "," ..
      schema.name .. "," ..
      size .. "," ..
      schema.description:sub(1,15)

  end

  list = list .. ";]"

  local formspec = [[
      size[16,12;]
      label[0,0;Search results (]] .. #list .. [[)]
      button_exit[0,11;4,1;allocate;Allocate]
      button_exit[4,11;4,1;load;Load]
      button_exit[12,11;4,1;exit;Exit]
      tablecolumns[text;text;text;text]
      table[0,1;15.7,10;items;User,Name,Size,Description]] .. list

  minetest.show_formspec(playername, FORMNAME, formspec)
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= FORMNAME then
		return
	end

	local selected_item = 0
	local playername = player:get_player_name()

	if fields.items then
		local parts = fields.items:split(":")
		if parts[1] == "CHG" then
			selected_item = tonumber(parts[2]) - 1
		end
	end

	if selected_item > 0 then
		local data = search_results[playername]
		local schema = data[selected_item]

		selected_item_data[playername] = schema
	end

	local schema = selected_item_data[playername]
	if not schema then
		return
	end

  if fields.load or fields.allocate then
    if not blockexchange.get_pos(1, playername) then
      minetest.chat_send_player(playername, "Select position 1 first with /bx_pos1")
      return
    end
  end

	if fields.load then
    blockexchange.download(
      playername,
      blockexchange.get_pos(1, playername),
      schema.user.name,
      schema.name
    )
  elseif fields.allocate then
    blockexchange.allocate(
      playername,
      blockexchange.get_pos(1, playername),
      schema.user.name,
      schema.name
    )
	end

end)


minetest.register_on_leaveplayer(function(player)
	search_results[player:get_player_name()] = nil
	selected_item_data[player:get_player_name()] = nil
end)
