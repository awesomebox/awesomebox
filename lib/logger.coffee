require 'colors'
util = require 'util'

class Logger
  constructor: (@name) ->
    @prompt = '[' + @name.toString().cyan + '] '
  
  log: ->
    text = util.format.apply(@, arguments)
    console.log @prompt + text
  
  error: ->
    text = util.format.apply(@, arguments)
    console.log @prompt + text.toString().red

module.exports = Logger
