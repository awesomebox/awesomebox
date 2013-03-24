require 'colors'
util = require 'util'

class Logger
  constructor: (@name) ->
    @prefix = '[' + @name.toString().cyan + '] '
  
  log: ->
    text = util.format.apply(@, arguments)
    console.log @prefix + text
  
  error: ->
    text = util.format.apply(@, arguments)
    console.log @prefix + text.toString().red

module.exports = Logger
