{EventEmitter} = require 'events'
async = require 'async'
express = require 'express'
portfinder = require 'portfinder'
Route = require './route'
View = require './view'

class Server extends EventEmitter
  constructor: (@opts = {}) ->
    @http = express()
    @plugins = []
    @__defineGetter__ 'address', => @raw_http.address()
  
  initialize: (callback) ->
    if @opts.watch
      livereload = require './plugins/livereload'
      @plugins.push(livereload())
    callback()
  
  configure_middleware: (callback) ->
    @http.use express.logger()
    @http.use(Route.respond)
    @http.use(Route.respond_error)
    @http.use(Route.not_found)
    callback()
  
  configure: (callback) ->
    for p in @plugins
      View.add_pipe(p.view_pipe()) if p.view_pipe?
    
    @configure_middleware(callback)
  
  start: (callback) ->
    listen = (port) =>
      @raw_http = @http.listen port, 'localhost', (err) =>
        return callback(err) if err?
        
        async.each @plugins, (p, cb) =>
          return cb() unless p.start?
          p.start(server: @, cb)
        , (err) =>
          return callback(err) if err?
          
          @emit('listening')
          callback()
    
    if @opts['hunt-port'] is false
      return listen(@opts.port) if @opts.port?
      return listen(8000)
    
    portfinder.basePort = @opts.port or 8000
    
    portfinder.getPort (err, port) =>
      return callback(err) if err?
      listen(port)
  
  stop: (callback) ->
    async.each @plugins, (p, cb) =>
      return cb() unless p.stop?
      p.stop(server: @, cb)
    , (err) =>
      return callback(err) if err?
      
      @http.close()
      callback()

module.exports = Server
