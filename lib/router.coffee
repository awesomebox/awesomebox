path = require 'path'
mime = require 'mime'
express = require 'express'
{helpers, Renderer} = require 'awesomebox-core'

class Router
  constructor: (@server) ->
    @root_dir = process.cwd()
    @template_dir = path.join(__dirname, 'templates')
    
    @tree = helpers.directory_tree(@root_dir)
    @static_middleware = express.static(@root_dir)
    
    @renderer_initializers = []
    
    @__defineGetter__ 'renderer', ->
      r = new Renderer(root: @root_dir)
      @renderer_initializers.forEach (i) -> i(r)
      r
    @__defineGetter__ 'template_renderer', ->
      r = new Renderer(root: @template_dir)
      @renderer_initializers.forEach (i) -> i(r)
      r
  
  send: (opts, req, res, next) ->
    content_type = opts.content_type
    unless content_type?
      content_type = mime.lookup(req.url)
      content_type = mime.lookup(opts.type) if content_type is 'application/octet-stream'
    
    res.status(opts.status_code or 200)
    res.set('Content-Type': content_type)
    res.send(opts.content)
  
  respond: (req, res, next) ->
    filename = helpers.find_file(@renderer.opts.root, req.url.split(/[#?]/)[0])
    return next() unless filename?
    return next() unless @tree.is_visible(filename) and @tree.is_file(filename)
    
    file = helpers.parse_filename(filename)
    return @static_middleware(req, res, next) if file.type in ['', 'data']
    
    @renderer.render(filename)
    .then (opts) =>
      return @static_middleware(req, res, next) unless opts.content?
      @send(opts, req, res, next)
    .catch(next)
    
  respond_error: (err, req, res, next) ->
    code = err.status if err.status?
    code = 500 if code < 400
    code ?= 500
    
    template = 'error.html.ejs'
    template = 'engine_error.html.ejs' if err.name is 'EngineError'
    
    @template_renderer.render(template, req: req, res: res, err: err)
    .then (opts) =>
      opts.status_code = code
      @send(opts, req, res, next)
    .catch(next)
  
  not_found: (req, res, next) ->
    @template_renderer.render('404.html.ejs', req: req, res: res)
    .then (opts) =>
      opts.status_code = 404
      opts.content_type = 'text/html'
      @send(opts, req, res, next)
    .catch(next)

module.exports = Router
