{EventEmitter} = require 'events'
express = require 'express'
flash = require 'connect-flash'
walkabout = require 'walkabout'
portfinder = require 'portfinder'

class Server extends EventEmitter
  constructor: ->
    @http = express()
    @__defineGetter__ 'address', => @raw_http.address()
    
    awesomebox.Plugins.wrap(@,
      'server.initialize': 'initialize'
      'server.configure': 'configure'
      'server.start': 'start'
      'server.stop': 'stop'
    )
    
  initialize: (callback) ->
    callback()
  
  configure_middleware: (callback) ->
    @http.use (req, res, next) ->
      console.log "#{req.method} #{req.url}"
      next()
    @http.use express.compress()
    @http.use express.bodyParser()
    @http.use express.methodOverride()
    @http.use express.cookieParser()
    @http.use express.session(secret: 'hohgah5Weegi0zae6vookaehoo0ieQu5')
    @http.use flash()
    @http.use @route.bind(@)
    @http.use express.static(awesomebox.path.root.join('public').absolute_path)
    callback()
  
  configure: (callback) ->
    @configure_middleware(callback)
  
  route: (req, res, next) ->
    route = new awesomebox.Route(req, res, next)
    route.respond()
  
  start: (callback) ->
    portfinder.getPort (err, port) =>
      return callback(err) if err?
      @raw_http = @http.listen port, (err) =>
        return callback(err) if err?
        @emit('listening')
        callback()
  
  stop: (callback) ->
    @http.close()
    callback()

module.exports = Server
