open = require 'open'

open_local = (server, args, results, next) ->
  server.on 'listening', ->
    awesomebox.logger.log "Listening on port #{server.address.port}"
    addr = server.address.address
    addr = 'localhost' if addr in ['0.0.0.0', '127.0.0.1']
    open("http://#{addr}:#{server.address.port}")
  next()

open_remote = (context, args, results, next) ->
  return if results[0]?
  config = JSON.parse(results[1].spawnWith.env.__AWESOMEBOX_CONFIG__)
  open("http://#{config.domain.split(',')[0]}")
  next()

module.exports = (context, done) ->
  context.on('pre:server.initialize', open_local)
  
  context.on('post:command.start', open_remote)
  context.on('post:command.deploy', open_remote)
  
  done()
