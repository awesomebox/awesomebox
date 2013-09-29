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
  
  exports.PartialPipeline
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
  
  path = cmd.resolved.path.dirname
  
  if path[0] is '/'
    layout_path = path
  else
    layout_path = cmd.resolved.path.directory().join(path)
  
  layout_pipeline = exports.LayoutPipeline
    .configure(_({}).extend(@config, {resolve_to: 'layouts'}))
  
  layout_pipeline.push(
    path: layout_path
    content_type: cmd.content_type
    data: cmd.data
    layout_content: cmd.content
  )
  .then (layout_cmd) ->
    cmd.content = layout_cmd.content if layout_cmd?.content?
    done()
  , done
  
  # don't return the promise from layout_pipeline.push
  null


walkabout = require 'walkabout'
betturl = require 'betturl'
tubing_view_utils = require 'tubing-view/dist/utils'

create_layout_paths = (path, content_type) ->
  paths = []
  
  while path isnt '/'
    paths.push("#{path}.#{content_type}")
    path = require('path').dirname(path)
  paths.push("/index.#{content_type}")
  
  paths

exports.resolve_layout_path = (cmd, done) ->
  root = @config.path[@config.resolve_to]
  path = cmd.parsed.path.replace(new RegExp('\.' + cmd.content_type + '$'), '')
  paths = create_layout_paths(path, cmd.content_type)

  # console.log 'RESOLVING LAYOUT PATH', @config.resolve_to, root.absolute_path, paths, cmd.content_type
  
  tubing_view_utils.resolve_path_from_root root, paths, (err, content_path, matched_path) =>
    return done(err) if err?
    return done() unless content_path?

    cmd.resolved =
      file: content_path
      path: walkabout(content_path.absolute_path.slice(root.absolute_path.length))

    # console.log 'RESOLVED LAYOUT TO', cmd.resolved.path.absolute_path
    
    engines = cmd.resolved.path.filename.slice(require('path').basename(matched_path).length + 1)
    engines = engines.replace(new RegExp('^(/?index)?\.' + cmd.content_type + '\.?'), '').split('.')
    cmd.engines = engines.filter((e) -> e? and e isnt '').reverse()
    
    done()

exports.resolve_partial_path = (cmd, done) ->
  path = cmd.parsed.path.replace(new RegExp('\.' + cmd.content_type + '$'), '')
  idx = path.lastIndexOf('/')
  if idx is -1
    path = '_' + path
  else
    path = path.slice(0, idx + 1) + '_' + path.slice(idx + 1)

  # console.log 'RESOLVING PARTIAL PATH', @config.resolve_to, @config.path[@config.resolve_to].absolute_path, path, cmd.content_type

  tubing_view_utils.resolve_path_from_root @config.path[@config.resolve_to], "#{path}.#{cmd.content_type}", (err, content_path) =>
    return done(err) if err?
    unless content_path?
      console.log 'Could not find partial at path ' + path
      return done()

    cmd.resolved =
      file: content_path
      path: walkabout(content_path.absolute_path.slice(@config.path[@config.resolve_to].absolute_path.length))

    # console.log 'RESOLVED PARTIAL TO', cmd.resolved.path.absolute_path

    engines = content_path.absolute_path.slice(content_path.absolute_path.lastIndexOf(path) + path.length)
    engines = engines.replace(new RegExp('^(/?index)?\.' + cmd.content_type + '\.?'), '').split('.')
    cmd.engines = engines.filter((e) -> e? and e isnt '').reverse()

    done()

exports.AutoInstallViewPipeline = tubing_view.ViewPipeline
  .insert(exports.install_engines, before: tubing_view.render_engines)
  .insert(
    tubing.exit_unless (cmd) -> cmd.mime_type.indexOf('text/') is 0 or cmd.mime_type in ['application/javascript', 'application/json']
    before: tubing_view.resolve_path
  )

exports.RenderPipeline = tubing.pipeline()
  .then(exports.configure)
  .then(exports.AutoInstallViewPipeline)
  .then(exports.wait_for_placeholders)

exports.LayoutPipeline = exports.RenderPipeline
  .insert(
    exports.AutoInstallViewPipeline.insert(exports.resolve_layout_path, instead_of: tubing_view.resolve_path)
    instead_of: exports.AutoInstallViewPipeline
  )

exports.PartialPipeline = exports.RenderPipeline
  .insert(
    exports.AutoInstallViewPipeline.insert(exports.resolve_partial_path, instead_of: tubing_view.resolve_path)
    instead_of: exports.AutoInstallViewPipeline
  )
