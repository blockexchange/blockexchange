
minetest.log("warning", "[TEST] integration-test enabled!")

minetest.register_on_mods_loaded(function()
	minetest.log("warning", "[TEST] starting tests")
	local pos1 = { x=0, y=0, z=0 }
	local pos2 = { x=50, y=20, z=50 }
	minetest.after(0, function()
		minetest.log("warning", "[TEST] emerging area")
		minetest.emerge_area(pos1, pos2, function(_, _, remaining)
			if remaining > 0 then return end

			minetest.log("warning", "[TEST] uploading schema")
			local ctx = blockexchange.upload("test", pos1, pos2, "description", {"test", "thing"})

			local callback

			callback = function()
				if ctx.success then
					minetest.log("warning", "[TEST] integration tests done!")
					minetest.request_shutdown("success")

					local data = minetest.write_json({ success = true }, true);
					local file = io.open(minetest.get_worldpath().."/integration_test.json", "w" );
					if file then
						file:write(data)
						file:close()
					end

				elseif ctx.failed then
					minetest.log("warning", "[TEST] integration tests done with errors!")
					minetest.request_shutdown("failed")
				end
				minetest.after(1, callback)
			end

			minetest.after(1, callback)
		end)
	end)

end)
