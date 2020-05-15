
local has_monitoring = minetest.get_modpath("monitoring")

local time_budget, process_count

if has_monitoring then
  time_budget = monitoring.counter("blockexchange_time_budget", "count of microseconds used in cpu time")
  process_count = monitoring.gauge("blockexchange_processes", "number of running processes")
end

local function scheduler()

  -- list of new processes
  local new_processes = {}

  -- execution timer
  local t0 = minetest.get_us_time()


  for _, ctx in ipairs(blockexchange.processes) do
    local t1 = minetest.get_us_time()
    local micros = t1 - t0

    if micros > (blockexchange.max_cpu_micros_per_second / 2) then
      -- cpu usage exceeded, take a break
      break
    end

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

  -- measure exec time in this step
  local t1 = minetest.get_us_time()

  if has_monitoring then
    local micros = t1 - t0
    time_budget.inc(micros)
    process_count.set(#new_processes)
  end


  -- re-schedule again after some delay
  minetest.after(0.5, scheduler)
end

-- delay init
minetest.after(1, scheduler)
