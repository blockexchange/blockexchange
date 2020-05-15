
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

  -- current time
  local now = os.time()

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

    -- setup process control callbacks
    local stopped = false
    local defer_seconds
    local process_control = {
      -- stops the process
      stop = function() stopped = true end,
      -- defers execution for this many seconds
      defer = function(seconds) defer_seconds = seconds end
    }

    -- check if process is deferred
    local execute_now = true
    if ctx._meta.deferred then
      if ctx._meta.defered < now then
        -- can be executed again, clear flag
        ctx._meta.defered = nil
      else
        -- don't execute now
        execute_now = false
      end
    end

    -- main execution in handler/worker function
    if execute_now then
      handler(ctx, process_control)
    end

    if defer_seconds then
      -- reschedule later
      ctx._meta.defered = now + defer_seconds
    end

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
