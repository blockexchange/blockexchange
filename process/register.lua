
-- name -> function(ctx) end
blockexchange.process_type_map = {}

-- registers a new process type
function blockexchange.register_process_type(name, fn)
  blockexchange.process_type_map[name] = fn
end


-- list<ctx>
blockexchange.processes = {}

-- schedules a process for execution
function blockexchange.register_process(ctx)
  table.insert(blockexchange.processes, ctx)
end
