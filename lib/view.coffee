mime = require 'mime'
async = require 'async'
express = require 'express'
walkabout = require 'walkabout'
tubing = require 'tubing'
tubing_view = require 'tubing-view'
{RenderPipeline, handle_layouts} = require './view_pipeline'

root = walkabout()
content_dir = root.join('content')
layouts_dir = root.join('layouts')
data_dir = root.join('data')

configure_paths = (cmd, done) ->
  @config.resolve_to = 'content'
  
  content_dir.exists (exists) =>
    @config.path = {}
    if exists
      @config.path.content = content_dir
      @config.path.layouts = layouts_dir
      @config.path.data = data_dir
    else
      @config.path.content = root

    @config.enabled =
      layouts: exists
      data: exists
    
    done()

HttpSink = tubing.sink (err, cmd) ->
  console.log(err.stack) if err?
  return cmd.next(err) if err?
  return express.static(@config.path.content.absolute_path)(cmd.req, cmd.res, cmd.next) unless cmd?.content?
  
  View.send_response(cmd.res, 200, cmd.content_type, cmd.content)

add_cheerio = (cmd, done) ->
  return done() unless cmd.content_type is 'html' and cmd.content?
  cmd.cheerio = require('cheerio').load(cmd.content)
  done()

write_cheerio_content = (cmd, done) ->
  return done() unless cmd.cheerio?
  
  cmd.content = cmd.cheerio.html()
  done()

compile_script_tags = (cmd, done) ->
  return done() unless cmd.cheerio?
  
  async.each cmd.cheerio('script[type]').toArray(), (el, cb) ->
    $el = cmd.cheerio(el)
    type = $el.attr('type')
    
    return cb() unless tubing_view.Engines.get_engine_by_attr_type(type)?
    
    tubing_view.Engines.install_engine_by_attr_type type, (err) ->
      return cb(err) if err?
    
      tubing_view.Engines.render_by_attr_type type, $el.html(), {}, (err, content) ->
        return cb(err) if err?
        
        script = '<script type="text/javascript"'
        script += ' ' + k + '="' + v + '"' for k, v of el.attribs when k isnt 'type'
        script += '>' + content + '</script>'
        
        $el.replaceWith(script)
        cb()
  , done

compile_style_tags = (cmd, done) ->
  return done() unless cmd.cheerio?
  
  async.each cmd.cheerio('style[type]').toArray(), (el, cb) ->
    $el = cmd.cheerio(el)
    type = $el.attr('type')
    
    return cb() unless tubing_view.Engines.get_engine_by_attr_type(type)?
    
    tubing_view.Engines.install_engine_by_attr_type type, (err) ->
      return cb(err) if err?
    
      tubing_view.Engines.render_by_attr_type type, $el.html(), {}, (err, content) ->
        return cb(err) if err?
        
        script = '<style type="text/css"'
        script += ' ' + k + '="' + v + '"' for k, v of el.attribs when k isnt 'type'
        script += '>' + content + '</style>'
        
        $el.replaceWith(script)
        cb()
  , done

ExtraPipeline = tubing.pipeline()
  .then(add_cheerio)
  .then(compile_script_tags, compile_style_tags)
  .then(write_cheerio_content)

HttpPipeline = tubing.pipeline('Http Pipeline')
  .then(configure_paths)
  .then(tubing_view.adapt_http_req)
  .then(tubing.exit_unless (cmd) -> mime.lookup(cmd.content_type).indexOf('text/') is 0)
  .then(RenderPipeline)
  .then(tubing.exit_unless('resolved'))
  .then(handle_layouts)
  .then (cmd) -> ExtraPipeline.configure(@config).push(cmd)

FileRenderPipeline = tubing.pipeline()
  .then(RenderPipeline)
  .then (cmd) -> ExtraPipeline.configure(@config).push(cmd)

http_pipeline = HttpPipeline.configure().publish_to(HttpSink)
file_render_pipeline = FileRenderPipeline.configure(
  resolve_to: 'content'
  path:
    content: walkabout('/')
)

class View
  @add_pipe: (pipe) ->
    ExtraPipeline = ExtraPipeline.insert(pipe, before: write_cheerio_content)
  
  @http_render: (req, res, next) ->
    http_pipeline.push(
      req: req
      res: res
      next: next
    )
  
  @render_file: (path, content_type, data, callback) ->
    if typeof data is 'function'
      callback = data
      data = {}
    
    file_render_pipeline.push(
      path: path
      content_type: content_type
      data: data
    ).then (cmd) ->
      callback(null, cmd?.content)
    , callback
  
  @send_response: (res, code, content_type, content) ->
    res.status(code)
    
    type = mime.lookup(content_type)
    
    if type.indexOf('text/')
      res.set('Content-Type': "#{type}; charset=#{mime.charsets.lookup(content_type)}")
    else
      res.set('Content-Type': type)
    
    res.send(content)

module.exports = View
