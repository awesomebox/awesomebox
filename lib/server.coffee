{EventEmitter} = require 'events'
async = require 'async'
express = require 'express'
# flash = require 'connect-flash'
portfinder = require 'portfinder'
Route = require './route'
View = require './view'

livereload = require('./plugins/livereload')()
mixpanel = require('./plugins/mixpanel')()

class Server extends EventEmitter
  constructor: ->
    @http = express()
    @plugins = [livereload, mixpanel]
    @__defineGetter__ 'address', => @raw_http.address()
  
  initialize: (callback) ->
    callback()
  
  configure_middleware: (callback) ->
    @http.use express.logger()
    # @http.use express.compress()
    # @http.use express.bodyParser()
    # @http.use express.methodOverride()
    # @http.use express.cookieParser()
    # @http.use express.session(secret: 'hohgah5Weegi0zae6vookaehoo0ieQu5')
    # @http.use flash()
    @http.use(Route.respond)
    @http.use(Route.respond_error)
    @http.use(Route.not_found)
    callback()
  
  configure: (callback) ->
    for p in @plugins
      View.add_pipe(p.view_pipe()) if p.view_pipe?
    
    @configure_middleware(callback)
  
  start: (callback) ->
    portfinder.basePort = 8000
    portfinder.getPort (err, port) =>
      return callback(err) if err?
      @raw_http = @http.listen port, (err) =>
        return callback(err) if err?
        
        async.each @plugins, (p, cb) =>
          return cb() unless p.start?
          p.start(server: @, cb)
        , (err) =>
          return callback(err) if err?
          
          @emit('listening')
          callback()
  
  stop: (callback) ->
    async.each @plugins, (p, cb) =>
      return cb() unless p.stop?
      p.stop(server: @, cb)
    , (err) =>
      return callback(err) if err?
      
      @http.close()
      callback()

module.exports = Server
