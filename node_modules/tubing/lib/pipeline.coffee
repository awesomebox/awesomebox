Q = require 'q'

index_of = (arr, predicate) ->
  for x in [0...arr.length]
    return x if predicate(arr[x])
  -1

class Definition
  constructor: (@name, @pipes = [], @config_methods = []) ->
  
  then: (pipes...) ->
    throw new Error('Cannot call .then without passing in at least 1 pipe') if pipes.length is 0
    
    Pipe = require './pipe'
    new Definition(@name, @pipes.concat(Pipe.define(pipes...)), @config_methods = [])
  
  insert: (pipes..., opts) ->
    throw new Error('Pipeline#insert() takes before, after, or instead_of') unless opts.before? or opts.after? or opts.instead_of?
    
    Pipe = require './pipe'
    
    pipe = Pipe.define(pipes...)
    hash = Pipe.define(opts.before or opts.after or opts.instead_of).hash
    
    pipes = @pipes.slice()
    x = index_of(pipes, (p) -> p.hash is hash)
    
    if x isnt -1
      if opts.before?
        pipes.splice(x, 0, pipe)
      else if opts.after?
        pipes.splice(x + 1, 0, pipe)
      else if opts.instead_of?
        pipes.splice(x, 1, pipe)
    
    new Definition(@name, pipes, @config_methods)
  
  remove: (pipes...) ->
    Pipe = require './pipe'
    
    hash = Pipe.define(opts.before).hash
    pipes = @pipes.slice().filter (pipe) ->
      pipe.hash isnt hash
    
    new Definition(@name, pipes, @config_methods)
  
  remove_nth: (n, pipes...) ->
    Pipe = require './pipe'

    hash = Pipe.define(opts.before).hash
    x = 0
    pipes = @pipes.slice().filter (pipe) ->
      return false if pipe.hash is hash and ++x is n
      true

    new Definition(@name, pipes, @config_methods)
  
  configure: (config) ->
    if typeof config is 'function'
      @config_methods.push(config)
      return @
    
    config ?= {}
    pipeline = new Pipeline(@, config)
    c(pipeline, config) for c in @config_methods
    pipeline

class Pipeline
  @Definition: Definition
  
  @define: (name) => new @Definition(name)
  
  constructor: (@definition, @config) ->
    @pipes = Array::slice.call(@definition.pipes)
    @sinks = []
  
  without: (pipes...) ->
    Pipe = require './pipe'
    
    hash = Pipe.define(pipes...).hash
    @pipes = @pipes.filter (p) -> p.hash isnt hash
    
    @
  
  without_nth: (n, pipes...) ->
    Pipe = require './pipe'
    
    hash = Pipe.define(pipes...).hash
    
    x = 0
    @pipes = @pipes.filter (p) ->
      if p.hash is hash
        ++x
        return n isnt x
      true
    
    @
  
  push: (cmd) ->
    deferred = Q.defer()
    
    finish_pipeline = (err, data) =>
      data ?= cmd
      
      if err?
        deferred.reject(err)
        s.process(context, err, data) for s in @sinks
        return
      
      deferred.resolve(data)
      s.process(context, null, data) for s in @sinks
    
    context = 
      Q: Q
      defer: -> Q.defer()
      config: @config
      pipeline: @
      exit_pipeline: finish_pipeline
    
    create_pipe_method = (pipe) ->
      (cmd) ->
        pipe.process(context, cmd)
    
    q = Q(cmd)
    for pipe in @pipes
      q = q.then(pipe.process.bind(pipe, context))
    
    q.then (data) ->
      finish_pipeline(null, data)
    , finish_pipeline
    
    deferred.promise
  
  publish_to: (sink) ->
    Sink = require './sink'
    sink = new Sink(sink) unless sink instanceof Sink
    @sinks.push(sink)
    @

Pipeline::__type__ = 'Pipeline'
Pipeline.Definition::__type__ = 'Pipeline.Definition'

module.exports = Pipeline
