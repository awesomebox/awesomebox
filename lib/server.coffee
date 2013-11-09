q = require 'q'
http = require 'http'
express = require 'express'
portfinder = require 'portfinder'
{EventEmitter} = require 'events'

Route = require './route'

class Server extends EventEmitter
  constructor: (@opts = {}) ->
    @app = express()
    @plugins = []
    @__defineGetter__ 'address', -> @http.address()
  
  start: ->
    @initialize()
    .then(@configure.bind(@))
    .then(@find_port.bind(@))
    .then(@listen.bind(@))
  
  stop: ->
    # stop plugins
    @plugins.reduce((o, p) =>
      return o unless p.stop?
      o.then(q.ninvoke(p, 'stop', server: @))
      o
    , q())
    .then =>
      @app.close()
  
  initialize: ->
    unless @_initialized
      @plugins.push(require('./plugins/livereload')()) if @opts.watch
      @_initialized = true
    q()
  
  configure: ->
    # install plugins...
    
    # for p in @plugins
    #   View.add_pipe(p.view_pipe()) if p.view_pipe?
    
    # configure middleware
    @app.use express.logger()
    @app.use Route.respond
    @app.use Route.respond_error
    @app.use Route.not_found
    q()
  
  find_port: ->
    if @opts['hunt-port'] is false
      @opts.port ?= 8000
    else
      portfinder.basePort = @opts.port or 8000
      q.ninvoke(portfinder, 'getPort')
      .then (port) =>
        @opts.port = port
  
  listen: ->
    d = q.defer()
    
    @http = http.createServer(@app).listen(@opts.port)
    @http.on 'error', (err) =>
      @emit('error', err)
      d.reject(err)
    @http.on 'listening', =>
      # start up plugins
      @plugins.reduce((o, p) =>
        return o unless p.start?
        o.then(q.ninvoke(p, 'start', server: @))
        o
      , q())
      .then =>
        @emit('listening')
        d.resolve()
      .catch (err) ->
        d.reject(err)
    
    d.promise

module.exports = Server
