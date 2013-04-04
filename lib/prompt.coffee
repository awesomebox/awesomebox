read = require 'read'

class Prompt
  constructor: (@opts) ->
    @opts ?= {}
    @opts = {prompt: @opts} if typeof @opts is 'string'
    @opts.input ?= process.stdin
    @opts.output ?= process.stdout
    @opts.prompt ?= '> '
    
    @prompt_length = (if @opts.prompt?.stripColors? then @opts.prompt.stripColors else @opts.prompt).length
  
  ask_for: (question, opts, callback) ->
    if typeof opts is 'function'
      callback = opts
      opts = {}
    
    read
      prompt: @opts.prompt + question
      promptLength: @prompt_length + question.length
      silent: opts.password
      replace: '#'
      input: @opts.input
      output: @opts.output
    , (err, line) =>
      return callback() if err?
      callback(line)

module.exports = Prompt
