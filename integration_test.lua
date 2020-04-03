
minetest.log("warning", "[TEST] integration-test enabled!")


local function doUpload(pos1, pos2, callback)
	minetest.log("warning", "[TEST] uploading schema")
	local ctx = blockexchange.upload("test", pos1, pos2, "description", {"test", "thing"})

	local done_check

	done_check = function()
		if ctx.success then
			callback(ctx.schema)

		elseif ctx.failed then
			minetest.log("warning", "[TEST] integration tests done with errors!")
			minetest.request_shutdown("failed")
		else
			minetest.after(1, done_check)
		end
	end

	minetest.after(1, done_check)
end

local function doDownload(pos1, uid, callback)
	minetest.log("warning", "[TEST] downloading schema")
	local ctx = blockexchange.download(pos1, uid)

	local done_check

	done_check = function()
		if ctx.success then
			callback(ctx.schema)

		elseif ctx.failed then
			minetest.log("warning", "[TEST] integration tests done with errors!")
			minetest.request_shutdown("failed")
		else
			minetest.after(1, done_check)
		end
	end

	minetest.after(1, done_check)
end



minetest.register_on_mods_loaded(function()
	minetest.log("warning", "[TEST] starting tests")
	local pos1 = { x=0, y=0, z=0 }
	local pos2 = { x=30, y=20, z=30 }
	minetest.after(0, function()
		minetest.log("warning", "[TEST] emerging area")
		minetest.emerge_area(pos1, pos2, function(_, _, remaining)
			if remaining > 0 then return end

			doUpload(pos1, pos2, function(schema)
				print("Uploaded schema: " .. dump(schema))
				local dl_pos1 = vector.add(pos1, 100)
				local uid = schema.uid

				doDownload(dl_pos1, uid, function()
					minetest.log("warning", "[TEST] integration tests done!")
					minetest.request_shutdown("success")

					local data = minetest.write_json({ success = true }, true);
					local file = io.open(minetest.get_worldpath().."/integration_test.json", "w" );
					if file then
						file:write(data)
						file:close()
					end
				end)
			end)

		end)
	end)

end)
