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
    
    if awesomebox.Plugins.context?
      awesomebox.Plugins.wrap(@,
        'route.render': 'render'
      )
  
  render: (url, callback) ->
    paths = [url]
    paths.unshift(Path.join(url, 'index.html')) if Path.extname(url) is ''
    
    View.render({path: paths, route: @}, callback)
  
  respond: ->
    @render @req.url, (err, data, view_opts) =>
      @req.awesomebox.view_opts = view_opts
      if err?
        return @next(err) unless err.code in ['EISDIR']
        return @next()
      return @next() unless data?
      
      @res.set('Content-Type': mime.lookup(view_opts.view_type))
      # @res.send(data)
      @res.send(_(view_opts.views).last().opts.rendered_content)

module.exports = Route
