express = require 'express'
flash = require 'connect-flash'
walkabout = require 'walkabout'

class Server
  constructor: ->
    @http = express()
    @__defineGetter__ 'address', => @raw_http.address()
  
  initialize: (callback) ->
    awesomebox.Plugins.server('initialize', @, callback)
  
  configure_middleware: ->
    @http.use express.compress()
    @http.use express.bodyParser()
    @http.use express.methodOverride()
    @http.use express.cookieParser()
    @http.use express.session(secret: 'hohgah5Weegi0zae6vookaehoo0ieQu5')
    @http.use flash()
    @http.use @route.bind(@)
  
  configure: (callback) ->
    @configure_middleware()
    awesomebox.Plugins.server('configure', @, callback)
  
  route: (req, res, next) ->
    route = new awesomebox.Route(req, res, next)
    route.respond()
  
  start: (callback) ->
    @raw_http = @http.listen 8000, (err) =>
      return callback(err) if err?
      awesomebox.Plugins.server('start', @, callback)
  
  stop: (callback) ->
    @http.close()
    awesomebox.Plugins.server('stop', @, callback)

module.exports = Server
