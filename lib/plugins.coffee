_ = require 'underscore'
async = require 'async'
walkabout = require 'walkabout'
liverequire = require './liverequire'

exports.plugins = []

class PluginContext
  constructor: ->
    @events = {}
  
  on: (event, method, context) ->
    @events[event] ?= []
    @events[event].push(method: method, context: context)
  
  wrap: (instance, event_name, method) ->
    m = instance[method]
    
    instance[method] = =>
      args = Array::slice.call(arguments)
      callback = _(args).last()
      if typeof callback is 'function'
        args = args[0...-1]
      else
        callback = ->
      
      event_methods = []
      Array::push.apply(event_methods, @events['pre:' + event_name]) if @events['pre:' + event_name]?.length > 0
      event_methods.push(method: m, context: instance, actual: true)
      Array::push.apply(event_methods, @events['post:' + event_name]) if @events['post:' + event_name]?.length > 0
      
      results = null
      async.eachSeries event_methods, (em, cb) ->
        if em.actual
          em.method.apply em.context, args.concat([->
            results = Array::slice.call(arguments)
            cb.apply(arguments)
          ])
        else
          em.method.call(em.context, instance, args, results, cb)
      , (err) ->
        return callback(err) if err?
        callback.apply(null, results)

exports.wrap = (instance, methods) ->
  if Array.isArray(methods)
    methods = _(methods).inject (o, m) ->
      o[m] = m
      o
    , {}
  
  exports.context.wrap(instance, k, v) for k, v of methods

exports.initialize = (callback) ->
  exports.context = new PluginContext()
  
  config = awesomebox.config
  return callback() unless config.plugins?
  config.plugins = [config.plugins] unless Array.isArray(config.plugins)
  
  liverequire config.plugins, (err, plugins) ->
    return callback(err) if err?
    exports.plugins = plugins
    
    async.eachSeries plugins, (p, cb) ->
      return cb() unless typeof p is 'function'
      p(exports.context, cb)
    , callback
