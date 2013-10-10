tubing = require '../lib/tubing'

incr = (field) ->
  (cmd, done) ->
    cmd[field] ?= 0
    cmd[field] += 1
    done()

filter = (fields...) ->
  (cmd, done) ->
    o = {}
    for f in fields
      o[f] = cmd[f] if cmd[f]?
    done(null, o)
    
print = (cmd, done) ->
  console.log cmd
  done()

p = tubing.pipeline('Test Pipeline')
  .then([incr, 'b'])
  .then([incr, 'd'])
  .then([incr, 'd'])
  .then([filter, 'a', 'c'])
  .insert([filter, 'f'], before: [incr, 'd'])
  .then(print)
  .configure (pipeline, config) ->
    console.log pipeline.pipes
    pipeline.without_nth(1, [incr, 'd'])
    console.log pipeline.pipes
  .configure()

p.push(
  a: 1
  b: 1
  c: 1
)
