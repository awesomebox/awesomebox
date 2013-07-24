{EventEmitter} = require 'events'
express = require 'express'
# flash = require 'connect-flash'
portfinder = require 'portfinder'
debug = require('debug')('awesomebox:server')

class Server extends EventEmitter
  constructor: ->
    @http = express()
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
    @http.use @route.bind(@)
    # @http.use express.static(awesomebox.path.content.absolute_path)
    callback()
  
  configure: (callback) ->
    @configure_middleware(callback)
  
  route: (req, res, next) ->
    new awesomebox.Route(req, res, next).respond()
  
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
