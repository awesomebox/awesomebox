async = require 'async'

exports.run = ->
  server = null
  
  async.series [
    (cb) -> awesomebox.Plugins.initialize(cb)
    (cb) -> server = new awesomebox.Server(); cb()
    (cb) -> server.initialize(cb)
    (cb) -> server.configure(cb)
    (cb) -> server.start(cb)
  ], (err) ->
    if err?
      awesomebox.logger.error err.message
      process.exit(1)
    
    awesomebox.logger.log "Listening on port #{server.address.port}"
    require('open') "http://#{server.address.address}:#{server.address.port}"
