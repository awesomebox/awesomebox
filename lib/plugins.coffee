_ = require 'underscore'
async = require 'async'
walkabout = require 'walkabout'
liverequire = require './liverequire'

exports.plugins = []

exports.initialize = (callback) ->
  awesome_file = awesome.path.root.join('awesome.json')
  
  if awesome_file.exists_sync()
    try
      config = require awesome_file.absolute_path
    catch e
      awesome.logger.error 'Could not parse your awesome.json file'
      process.exit(1)

    if config.plugins?
      config.plugins = [config.plugins] unless Array.isArray(config.plugins)
      liverequire config.plugins, (err, plugins) ->
        return callback(err) if err?
        exports.plugins = plugins
        callback()

exports.of_type = (type) ->
  type = type.split('.')
  
  exports.plugins.filter (plugin) ->
    c = plugin
    _(type).every (t) ->
      c = c[t]
      c?

exports.server = (method, server, callback) ->
  plugins = exports.of_type("server.#{method}")
  return callback?() if plugins.length is 0
  
  async.eachSeries plugins, (plugin, cb) ->
    plugin.server[method](server, cb)
  , (err) ->
    return callback?(err) if err?
    callback?()

exports.view = {
  after_render: ($, view, callback) ->
    plugins = exports.of_type('view.after_render')
    return callback?(null, $) if plugins.length is 0
    
    async.eachSeries plugins, (plugin, cb) ->
      plugin.view.after_render($, view, cb)
    , (err) ->
      return callback?(err) if err?
      callback?(null, $)
}
