path = require 'path'
mime = require 'mime'
express = require 'express'
{helpers, Renderer} = require 'awesomebox-core'

renderer = new Renderer(root: process.cwd())
template_renderer = new Renderer(root: path.join(__dirname, 'templates'))
static_middleware = express.static(process.cwd())

class Route
  @respond: (req, res, next) ->
    file = helpers.find_file(renderer.opts.root, req.url)
    return next() unless file?
    
    renderer.render(file)
    .then (opts) ->
      return static_middleware(req, res, next) unless opts.content?
      Route.send(opts, req, res, next)
    .catch(next)
  
  @send: (opts, req, res, next) ->
    content_type = opts.content_type
    unless content_type?
      content_type = mime.lookup(req.url)
      content_type = mime.lookup(opts.type) if content_type is 'application/octet-stream'
    
    res.status(opts.status_code or 200)
    res.set('Content-Type': content_type)
    res.send(opts.content)
  
  @respond_error: (err, req, res, next) ->
    code = err.status if err.status?
    code = 500 if code < 400
    code ?= 500
    
    template_renderer.render('error.html.ejs', req: req, res: res, err: err)
    .then (opts) ->
      opts.status_code = code
      Route.send(opts, req, res, next)
    .catch(next)
  
  @not_found: (req, res, next) ->
    template_renderer.render('404.html.ejs', req: req, res: res)
    .then (opts) ->
      opts.status_code = 404
      Route.send(opts, req, res, next)
    .catch(next)

module.exports = Route
