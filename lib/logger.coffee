require 'colors'
util = require 'util'

class Logger
  constructor: (@name) ->
    @prompt = '[' + @name.toString().cyan + '] '
  
  log: ->
    text = util.format.apply(@, arguments)
    console.log @prompt + text
  
  success: ->
    text = util.format.apply(@, arguments)
    console.log text.split('\n').map((line) => @prompt + line.green).join('\n')
    # console.log @prompt + text.green
  
  error: ->
    text = util.format.apply(@, arguments)
    console.log @prompt + text.toString().red

module.exports = Logger
