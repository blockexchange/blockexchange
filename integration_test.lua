
minetest.log("warning", "[TEST] integration-test enabled!")


local function doUpload(pos1, pos2, callback)
	minetest.log("warning", "[TEST] uploading schema")
	local ctx = blockexchange.upload("test", pos1, pos2, "description", {"test", "thing"})

	local done_check

	done_check = function()
		if ctx.success then
			callback(ctx.schema)
		elseif ctx.failed then
			error(dump(ctx))
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
			error(dump(ctx))
		else
			minetest.after(1, done_check)
		end
	end

	minetest.after(1, done_check)
end

local pos1 = { x=0, y=0, z=0 }
local pos2 = { x=30, y=20, z=30 }
local dl_pos1 = vector.add(pos1, 100)

local username = "max_muster"
local password = "n00b"

minetest.register_on_mods_loaded(function()
	minetest.log("warning", "[TEST] starting tests")
	minetest.after(0, function()
		minetest.log("warning", "[TEST] emerging area")
		minetest.emerge_area(pos1, pos2, function(_, _, remaining)
			if remaining > 0 then return end

			blockexchange.api.register(username, password, nil, function(result)
				if not result.success then
					minetest.log("error", "register: " .. dump(result))
				end

				blockexchange.api.get_token(username, password, function(token)
					blockexchange.tokens[username] = token
					doUpload(pos1, pos2, function(schema)
						print("Uploaded schema: " .. dump(schema))

						doDownload(dl_pos1, schema.uid, function()
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
			end, function(http_code)
				error(http_code)
			end)
		end)
	end)

end)
