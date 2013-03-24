async = require 'async'

exports.run = ->
  server = null
  
  async.series [
    (cb) -> awesome.Plugins.initialize(cb)
    (cb) -> server = new awesome.Server(); cb()
    (cb) -> server.initialize(cb)
    (cb) -> server.configure(cb)
    (cb) -> server.start(cb)
  ], (err) ->
    if err?
      awesome.logger.error err.message
      process.exit(1)
    
    awesome.logger.log "Listening on port #{server.address.port}"
