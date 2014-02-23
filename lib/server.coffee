q = require 'q'
http = require 'http'
express = require 'express'
portfinder = require 'portfinder'
{EventEmitter} = require 'events'

Config = require './config'
Router = require './router'

class Server extends EventEmitter
  constructor: (@opts = {}) ->
    @app = express()
    @router = new Router(@)
    @plugins = []
    @__defineGetter__ 'address', -> @http.address()
  
  start: ->
    @initialize()
    .then(@configure.bind(@))
    .then(@find_port.bind(@))
    .then(@listen.bind(@))
  
  stop: ->
    # stop plugins
    @plugins.reduce (o, p) ->
      o.then -> p.stop?()
    , q()
    .then =>
      @app.close()
  
  initialize: ->
    unless @_initialized
      @config = Config.load(process.cwd())
      
      @plugins.push(require('./plugins/livereload')) if @opts.watch
      @plugins.push(@config.plugins...)
      
      @_initialized = true
    q()
  
  configure: ->
    # instantiate plugins
    @plugins = @plugins.map (p) => p(@)
    
    q()
    .then =>
      # install plugins...
      @plugins.reduce (o, p) ->
        o.then ->
          q.when(p.install?())
      , q()
    .then =>
      # configure middleware
      # @app.use express.logger()
      @app.use @router.respond.bind(@router)
      @app.use @router.respond_error.bind(@router)
      @app.use @router.not_found.bind(@router)
  
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
      # start plugins
      @plugins.reduce (o, p) ->
        o.then -> p.start?()
      , q()
      .then =>
        @emit('listening')
        d.resolve()
      .catch (err) ->
        d.reject(err)
    
    d.promise

module.exports = Server
