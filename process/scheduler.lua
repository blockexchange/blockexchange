
local function scheduler()

  -- list of new processes
  local new_processes = {}

  for _, ctx in ipairs(blockexchange.processes) do
    assert(ctx.type)
    local handler = blockexchange.process_type_map[ctx.type]
    assert(handler)

    local stopped = false
    local process_control = {
      stop = function() stopped = true end
    }

    handler(ctx, process_control)

    if not stopped then
      table.insert(new_processes, ctx)
    end
  end

  -- assign new processes
  blockexchange.processes = new_processes

  -- re-schedule again after some delay
  minetest.after(0.5, scheduler)
end

-- delay init
minetest.after(1, scheduler)
