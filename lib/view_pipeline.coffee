_ = require 'underscore'
mime = require 'mime'
async = require 'async'
tubing = require 'tubing'
betturl = require 'betturl'
express = require 'express'
tubing_view = require 'tubing-view'

Parsers = require './parsers'

npm_install = (pkg, version, callback) ->
  if typeof version is 'function'
    callback = version
    version = null
  
  pkg = "#{pkg}@#{version}" if version?
  
  npm = require 'npm'
  npm.load {prefix: process.cwd() + '/node_modules'}, (err) ->
    return callback(err) if err?
    
    npm.commands.install [pkg], (err, data) ->
      return callback(err) if err?
      callback()

box_raw_data = (path) ->
  data_path = tubing_view.utils.resolve_path_from_root_sync(@config.path.data, path)
  return throw new Error('No data file available at ' + path) unless data_path?
  
  data_path.read_file_sync()

box_data = (path) ->
  # make it so we can load xml, yml, json, etc...
  # try to load remote sources too...
  
  data_path = tubing_view.utils.resolve_path_from_root_sync(@config.path.data, path)
  throw new Error('No data file available at ' + path) unless data_path?
  
  parser = Parsers.get_parser(data_path.extension)
  throw new Error("Parser #{data_path.extension} is not supported") unless parser?
  
  data = data_path.read_file_sync()
  parser.process(data_path.extension, data)

PARTIAL_NUMBER = parseInt(Math.random() * 1000000)

box_partial = (cmd, path, partial_data) ->
  d = @defer()
  cmd.placeholders.push(d.promise)
  
  placeholder = "<[PARTIAL-#{PARTIAL_NUMBER++}]>"
  
  if path[0] is '/'
    partial_path = path
  else
    partial_path = cmd.resolved.path.directory().join(path)
  
  partial_pipeline = exports.PartialPipeline.configure(@config)
  partial_pipeline.publish_to (err, partial_cmd) ->
    return d.reject(err) if err?
    cmd.content = cmd.content.replace(placeholder, partial_cmd.content) if partial_cmd?
    d.resolve()
  
  partial_pipeline.push(
    parsed: betturl.parse(partial_path)
    content_type: cmd.content_type
    data: _({}).extend(cmd.data, partial_data)
  )
  
  placeholder

box_layout = (cmd) ->
  cmd.layout_content or ''

box_content = (cmd, path, data) ->
  return box_partial.call(@, cmd, path, data) if path?
  box_layout.call(@, cmd)

exports.configure = (cmd, done) ->
  cmd.placeholders = []
  
  cmd.data ?= {}
  cmd.data.box ?= {}
  cmd.data.box.data = box_data.bind(@)
  cmd.data.box.data.raw = box_raw_data.bind(@)
  cmd.data.box.content = box_content.bind(@, cmd)
  
  cmd.data.query = cmd.data.query or cmd.parsed.query
  
  done()

exports.install_engines = (cmd, done) ->
  engines = _.chain(cmd.engines).map((e) -> tubing_view.Engines.get_engine(e).dependencies).flatten().uniq().value()
  return done() if engines.length is 0
  
  async.each engines, (e, cb) ->
    try
      res = require.resolve(process.cwd() + '/node_modules/' + e)
      return npm_install(e, cb) unless require('path').relative(process.cwd(), res).indexOf('..') is -1
      cb()
    catch err
      npm_install(e, cb)
  , (err) ->
    return done(err) if err?
    done()

exports.wait_for_placeholders = (cmd, done) ->
  check = =>
    return done() if cmd.placeholders.length is 0
  
    promise = @Q.all(cmd.placeholders)
    cmd.placeholders = []
  
    promise.then ->
      check()
    , (err) ->
      done(err)
  
  check()

exports.handle_layouts = (cmd, done) ->
  return done() unless cmd.content_type is 'html'
  
  path = cmd.resolved.path.dirname
  
  if path[0] is '/'
    layout_path = path
  else
    layout_path = cmd.resolved.path.directory().join(path)
  
  layout_pipeline = exports.LayoutPipeline.configure(@config)
  layout_pipeline.publish_to (err, layout_cmd) ->
    return done(err) if err?
    cmd.content = layout_cmd.content if layout_cmd?.content?
    done()
  
  layout_pipeline.push(
    parsed: betturl.parse(layout_path)
    content_type: cmd.content_type
    data: cmd.data
    layout_content: cmd.content
  )
  
  null

exports.PartialPipeline = tubing.pipeline('Awesomebox Partial View Pipeline')
  .then(exports.configure)
  .then(tubing_view.resolve_path('content'))
  .then(exports.install_engines)
  .then(tubing_view.fetch_content)
  .then(tubing_view.render_engines)
  .then(exports.wait_for_placeholders)

exports.LayoutPipeline = tubing.pipeline('Awesomebox Layout View Pipeline')
  .then(tubing.exit_unless_config_true('enable_layouts'))
  .then(exports.configure)
  .then(tubing_view.resolve_path('layouts'))
  .then(tubing.exit_unless('resolved'))
  .then(exports.install_engines)
  .then(tubing_view.fetch_content)
  .then(tubing_view.render_engines)
  .then(exports.wait_for_placeholders)

exports.ViewPipeline = tubing.pipeline('Awesomebox View Pipeline')
  .then(tubing_view.configure)
  .then(exports.configure)
  .then(tubing_view.resolve_path('content'))
  .then(tubing.exit_unless('resolved'))
  .then(exports.install_engines)
  .then(tubing_view.fetch_content)
  .then(tubing_view.render_engines)
  .then(exports.wait_for_placeholders)
  .then(exports.handle_layouts)

exports.HttpSink = tubing.sink (err, cmd) ->
  return cmd.next(err) if err?
  return express.static(@config.path.content.absolute_path)(cmd.req, cmd.res, cmd.next) unless cmd?.content?
  
  cmd.res.set('Content-Type': mime.lookup(cmd.content_type))
  cmd.res.send(cmd.content)
