_ = require 'underscore'
mime = require 'mime'
async = require 'async'
walkabout = require 'walkabout'
compiler = require 'connect-compiler'
Path = require 'path'

View = require('./view').configure(
  view_root: awesomebox.path.content
  layout_root: awesomebox.path.layouts
  use_layouts: true
)

class Route
  constructor: (@req, @res, @next) ->
    @req.awesomebox ?= {}
    @req.awesomebox.route = @
  
  respond: ->
    paths = [@req.url]
    paths.unshift(Path.join(@req.url, 'index.html')) if Path.extname(@req.url) is ''
    
    View.render {path: paths, route: @}, (err, data, view_opts) =>
      @req.awesomebox.view_opts = view_opts
      if err?
        return @next(err) unless err.code in ['EISDIR']
        return @next()
      return @next() unless data?
      
      @res.set('Content-Type': mime.lookup(view_opts.view_type))
      @res.send(data)

module.exports = Route
