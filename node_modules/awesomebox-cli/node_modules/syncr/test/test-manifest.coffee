async = require 'async'
syncr = require '../lib/syncr'

async.parallel
  lhs: (cb) -> syncr.create_manifest('./', ignore_file: __dirname + '/manifestignore', cb)
  rhs: (cb) -> syncr.create_manifest('./', cb)
, (err, data) ->
  console.log data.lhs
  console.log data.rhs
  
  console.log syncr.compute_delta(data.lhs, data.rhs)
