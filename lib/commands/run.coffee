exports.execute = (context, callback) ->
  async = require 'async'
  
  server = new awesomebox.Server()
  
  async.series [
    (cb) -> server.initialize(cb)
    (cb) -> server.configure(cb)
    (cb) -> server.start(cb)
  ], (err) ->
    return callback(err) if err?
    
    awesomebox.logger.log 'Listening on port ' + server.address.port
    callback()
