_ = require 'underscore'
async = require 'async'
tubing = require 'tubing'
tubing_view = require 'tubing-view'

Parsers = require './parsers'

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
  
  exports.RenderPipeline
    .configure(@config)
    .push(
      path: partial_path
      content_type: cmd.content_type
      data: _({}).extend(cmd.data, partial_data)
    )
    .then (partial_cmd) ->
      # console.log 'PARTIAL SUCCESS', partial_cmd
      if partial_cmd?
        cmd.content = cmd.content.replace(placeholder, partial_cmd.content)
      else
        cmd.content = cmd.content.replace(placeholder, '')
      d.resolve()
    , (err) ->
      console.log 'PARTIAL ERROR', err.stack
      cmd.content = cmd.content.replace(placeholder, '')
      d.reject(err)
  
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
  
  done()

exports.install_engines = (cmd, done) ->
  return done() if cmd.engines is 0
  
  async.each cmd.engines, (e, cb) ->
    tubing_view.Engines.install_engine_by_ext(e, cb)
  , done

exports.wait_for_placeholders = (cmd, done) ->
  check = =>
    try
      return done() if cmd.placeholders.length is 0
  
      promise = @Q.all(cmd.placeholders)
      cmd.placeholders = []
  
      promise.then ->
        check()
      , (err) ->
        done(err)
    catch err
      console.log err.stack
  
  check()

exports.handle_layouts = (cmd, done) ->
  return done() unless @config.enabled.layouts is true and cmd.content_type is 'html'
  
  # console.log 'HANDLE LAYOUTS'
  
  path = cmd.resolved.path.dirname
  
  if path[0] is '/'
    layout_path = path
  else
    layout_path = cmd.resolved.path.directory().join(path)
  
  layout_pipeline = exports.RenderPipeline
    .insert((cmd, done) ->
      # console.log 'STARTING LAYOUTS'
      # console.log arguments
      done()
    , {before: exports.configure})
    .configure(_({}).extend(@config, {resolve_to: 'layouts'}))
  
  layout_pipeline.push(
    path: layout_path
    content_type: cmd.content_type
    data: cmd.data
    layout_content: cmd.content
  ).then (layout_cmd) ->
    cmd.content = layout_cmd.content if layout_cmd?.content?
    done()
  , done

exports.RenderPipeline = tubing.pipeline()
  .then(exports.configure)
  .then(
    tubing_view.ViewPipeline
      .insert(exports.install_engines, before: tubing_view.render_engines)
  )
  .then(exports.wait_for_placeholders)

exports.LayoutPipeline = tubing.pipeline()
  .then(exports.handle_layouts)
