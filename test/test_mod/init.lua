
minetest.log("warning", "[TEST] integration-test enabled!")

local playername = "max"
local username = "test"
local token_value = "xyz"

local function doEmerge(pos1, pos2, callback)
	local ctx = blockexchange.emerge(playername, pos1, pos2)

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

local function doUpload(pos1, pos2, callback)
	minetest.log("warning", "[TEST] uploading schema")
	local ctx = blockexchange.protectioncheck(playername, pos1, pos2, "my_schema", "description")

	local done_check

	done_check = function()
		if ctx.success and ctx.upload_ctx and ctx.upload_ctx.success then
			callback(ctx.upload_ctx.schema)
		elseif ctx.failed or (ctx.upload_ctx and ctx.upload_ctx.failed) then
			error(dump(ctx))
		else
			minetest.after(1, done_check)
		end
	end

	minetest.after(1, done_check)
end

local function doDownload(pos1, callback)
	minetest.log("warning", "[TEST] downloading schema")
	local ctx = blockexchange.download(playername, pos1, username, "my_schema")

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


minetest.register_on_mods_loaded(function()
	minetest.log("warning", "[TEST] starting tests")
	minetest.after(0, function()
		minetest.log("warning", "[TEST] emerging area")
		doEmerge(pos1, pos2, function()
			blockexchange.api.get_token("test", token_value, function(token)
				assert(token)
				blockexchange.tokens[playername] = token
				doUpload(pos1, pos2, function(schema)
					print("Uploaded schema: " .. dump(schema))
					-- execute allocation
					blockexchange.allocate(playername, pos1, username, schema.name)

					doDownload(dl_pos1, function()
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
			end, function(http_code)
				error(http_code)
			end)
		end)
	end)

end)
