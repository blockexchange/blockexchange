
minetest.log("warning", "[TEST] integration-test enabled!")

minetest.register_on_mods_loaded(function()
	minetest.after(1, function()

		local data = minetest.write_json({ success = true }, true);
		local file = io.open(minetest.get_worldpath().."/integration_test.json", "w" );
		if file then
			file:write(data)
			file:close()
		end

		file = io.open(minetest.get_worldpath().."/registered_nodes.txt", "w" );
		if file then
			for name in pairs(minetest.registered_nodes) do
				file:write(name .. '\n')
			end
			file:close()
		end

		minetest.log("warning", "[TEST] starting tests")
		local pos1 = { x=0, y=0, z=0 }
		local pos2 = { x=15, y=15, z=15 }
		minetest.after(0, function()
			minetest.log("warning", "[TEST] emerging area")
			minetest.emerge_area(pos1, pos2, function()
				minetest.log("warning", "[TEST] testing serializer")
				minetest.set_node(pos1, { name = "default:chest" })
				local meta = minetest.get_meta(pos1)
				local inv = meta:get_inventory()
				inv:set_size("main", 8*4)
				inv:set_stack("main", 1, ItemStack("default:cobble 99"))

				local part = blockexchange.serialize_part(pos1, pos2)
				print("metadata: " .. minetest.write_json(part.metadata))
				print("node_mapping: " .. minetest.write_json(part.node_mapping))
				print("size: " .. minetest.write_json(part.size))

				minetest.log("warning", "[TEST] uploading schema")
				blockexchange.upload("test", pos1, pos2, "description", {"test", "thing"})

				minetest.after(10, function()
					minetest.log("warning", "[TEST] integration tests done!")
					minetest.request_shutdown("success")
				end)
			end)
		end)

	end)
end)
