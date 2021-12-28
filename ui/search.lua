local FORMNAME = "blockexchange_search"

if not minetest.features.dynamic_add_media_table then
    minetest.log("warning", "[blockexchange] search disabled due to missing dynamic_add_media_table feature")
    return
end

-- playername -> result
local search_results = {}
-- playername -> index
local selected_result_items = {}
-- playername -> name
local preview_image = {}

function blockexchange.ui.search(playername)
    local list = ""
    for _, schema in ipairs(search_results[playername] or {}) do
        local s_size = blockexchange.get_schema_size(schema)
        local size = s_size.x .. " / " .. s_size.y .. " / " .. s_size.z

        list = list .. "," ..
            schema.user.name .. "," ..
            schema.name .. "," ..
            size

    end
    local selected_result_item = selected_result_items[playername] or 0
    list = list .. ";" .. (selected_result_item + 1) .. "]"

    local preview = ""
    if preview_image[playername] then
        preview = "image[8.2,7;7.8,5.2;" .. preview_image[playername] .. "]"
    end

    local description = "Search and select a schematic"
    if search_results[playername] and search_results[playername][selected_result_item] then
        local schema = search_results[playername][selected_result_item]
        description = "Name: " .. schema.name .. "\n" ..
            "License: " .. schema.license .. "\n" ..
            "Size in bytes: " .. schema.total_size .. "\n" ..
            "Description: " .. schema.description
    end

    local formspec = [[
        size[16,12;]
        field[0.2,0.4;14,0.8;keywords;Keywords;]
        field_close_on_enter[keywords;false]
        button[14.1,0.1;1.8,0.8;search;Search]
        tablecolumns[text;text;text]
        table[0,1.1;7.8,10.8;items;User,Name,Size]] .. list .. [[
        textarea[8.2,1.5;7.8,5.2;;;]] .. description .. [[]
        ]] .. preview .. [[
    ]]

    minetest.show_formspec(playername, FORMNAME, formspec)
end

-- clear and recreate media cache
minetest.rmdir(minetest.get_worldpath() .. "/bx_media", true)
minetest.mkdir(minetest.get_worldpath() .. "/bx_media")

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= FORMNAME then
		return
	end

    local playername = player:get_player_name()

    if fields.items then
        local parts = fields.items:split(":")
        if parts[1] == "CHG" then
            local item_index = tonumber(parts[2]) - 1
            selected_result_items[playername] = item_index
            blockexchange.ui.search(playername)

            if search_results[playername] and search_results[playername][item_index] then
                local schema = search_results[playername][item_index]
                blockexchange.api.get_schemascreenshots(schema.id):next(function(screenshots)
                    return blockexchange.api.get_schemascreenshot(schema.id, screenshots[1].id)
                end):next(function(screenshot)
                    local texture_name = playername .. os.time() .. ".png"
                    local filename = minetest.get_worldpath() .. "/bx_media/" .. texture_name
                    local file = io.open(filename, "w")
                    if file and file:write(screenshot) and file:close() then
                        minetest.dynamic_add_media({
                            filepath = filename,
                            to_player = playername,
                            ephemeral = true
                        }, function()
                            preview_image[playername] = texture_name
                            blockexchange.ui.search(playername)
                        end)
                    end
                end):catch(function(err)
                    print(err)--XXX
                end)
            end
            return
        end
    end

    if fields.keywords and fields.keywords ~= "" then
        blockexchange.api.find_schema_by_keywords(fields.keywords):next(function(result)
            -- re-populate search results
            search_results[playername] = result
            preview_image[playername] = nil
            selected_result_items[playername] = nil

            blockexchange.ui.search(playername)
        end):catch(function(err)
            -- TODO: error handling
            print(err)
        end)
    end
end)
