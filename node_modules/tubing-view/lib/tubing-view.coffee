mime = require 'mime'
tubing = require 'tubing'
betturl = require 'betturl'
walkabout = require 'walkabout'

utils = exports.utils = require './utils'
Engines = exports.Engines = require './engines'

exports.adapt_http_req = (cmd, done) ->
  cmd.path = cmd.req.url
  
  cmd.req.view ?= {}
  cmd.req.view.pipeline = @pipeline
  cmd.req.view.command = cmd
  
  done()

exports.resolve_content_type = (cmd, done) ->
  try
    cmd.parsed = betturl.parse(cmd.path)
  
    unless cmd.content_type?
      content_type = mime.lookup(cmd.parsed.path)
      content_type = cmd.req.accepted[0].value if content_type is 'application/octet-stream' and cmd.req?
      cmd.content_type = mime.extension(content_type)
    
    try
      cmd.mime_type = mime.lookup(cmd.content_type)
    catch err
      cmd.mime_type = 'text/plain'
    cmd.mime_charset = mime.charsets.lookup(cmd.mime_type)
  catch err
    return done(err)
  
  done()

exports.resolve_path = (cmd, done) ->
  path = cmd.parsed.path.replace(new RegExp('\.' + cmd.content_type + '$'), '')
  paths = ["#{path}.#{cmd.content_type}", "#{path}/index.#{cmd.content_type}"]
  path_base = cmd.parsed.path.slice(cmd.parsed.path.lastIndexOf('/') + 1)
  paths.push(cmd.parsed.path) if new RegExp("\\b#{cmd.content_type}\\b").test(path_base)
  
  # console.log 'RESOLVING PATH', @config.resolve_to, @config.path[@config.resolve_to].absolute_path, path, cmd.content_type
  
  utils.resolve_path_from_root @config.path[@config.resolve_to], paths, (err, content_path) =>
  
  # utils.resolve_path_from_root_with_extension @config.path[@config.resolve_to], path, cmd.content_type, (err, content_path) =>
    console.log(err.stack) if err?
    return done(err) if err?
    return done() unless content_path?
  
    cmd.resolved =
      file: content_path
      path: walkabout(content_path.absolute_path.slice(@config.path[@config.resolve_to].absolute_path.length))
    
    # console.log 'RESOLVED TO', cmd.resolved.path.absolute_path
    
    engines = content_path.absolute_path.slice(content_path.absolute_path.lastIndexOf(path) + path.length)
    engines = engines.replace(new RegExp('^(/?index)?\.' + cmd.content_type + '\.?'), '').split('.')
    cmd.engines = engines.filter((e) -> e? and e isnt '').reverse()
  
    done()

exports.fetch_content = (cmd, done) ->
  cmd.resolved.file.read_file (err, content) ->
    return done(err) if err?
    cmd.content = content.toString()
    done()

exports.create_params = (cmd, done) ->
  cmd.data ?= {}
  cmd.data.params ?= {}
  cmd.data.params[k] = v for k, v of cmd.parsed.query
  
  done()

exports.render_engines = (cmd) ->
  d = @defer()
  
  step = (idx) ->
    return d.resolve(cmd) if idx is cmd.engines.length
    
    try
      Engines.render cmd.engines[idx], cmd.content, cmd.data, cmd.resolved.file.absolute_path, (err, data) ->
        return d.reject(err) if err?
        cmd.content = data
        step(idx + 1)
    catch err
      return d.reject(err)
    
  step(0)
  
  d.promise

exports.ViewPipeline = tubing.pipeline('View Pipeline')
  .then(exports.resolve_content_type)
  .then(exports.resolve_path)
  .then(tubing.exit_unless('resolved'))
  .then(exports.fetch_content)
  .then(exports.create_params)
  .then(exports.render_engines)
  
  .configure (pipeline, config) ->
    config.path[k] = walkabout(config.path[k]) for k in config.path

exports.HttpViewPipeline = tubing.pipeline('Http View Pipeline')
  .then(exports.adapt_http_req)
  .then(exports.ViewPipeline)
