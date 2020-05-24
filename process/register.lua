
-- name -> function(ctx) end
blockexchange.process_type_map = {}

-- registers a new process type
function blockexchange.register_process_type(name, fn)
  blockexchange.process_type_map[name] = fn
end


-- list<ctx>
blockexchange.processes = {}

-- schedules a process for execution
function blockexchange.start_process(ctx)
  -- add process metadata
  ctx._meta = {
    -- process id
    id = math.floor(math.random() * 10000),
    -- start time of the process
    start_time = os.time()
  }
  table.insert(blockexchange.processes, ctx)
end
