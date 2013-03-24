_ = require 'underscore'
mime = require 'mime'
async = require 'async'
walkabout = require 'walkabout'

doSeries = (fn) ->
  ->
    args = Array::slice.call(arguments)
    fn.apply(null, [async.eachSeries].concat(args))

_first = (eachfn, arr, iterator, main_callback) ->
  eachfn arr, (x, callback) ->
    iterator x, (err, result) ->
      return callback(err) if err?
      return callback() unless result?
      main_callback(null, result)
      main_callback = ->
  , main_callback

firstSeries = doSeries(_first)

class Route
  constructor: (@req, @res, @next) ->
  
  find_template: (root, request_type, callback) ->
    paths = [root.join("index.#{request_type}"), root]
    
    firstSeries paths, (p, cb) =>
      awesomebox.View.find_template_file(p, cb)
    ,  callback
  
  find_layout: (root, request_type, callback) ->
    relative = walkabout(awesomebox.path.layout.join(require('path').relative(awesomebox.path.html.absolute_path, root.absolute_path)).dirname)
    
    paths = [awesomebox.path.layout.join('default.' + request_type)]
    until relative.absolute_path is awesomebox.path.layout.absolute_path
      paths.unshift(walkabout(relative.absolute_path + '.' + request_type))
      relative = walkabout(relative.dirname)
    
    firstSeries paths, (p, cb) =>
      awesomebox.View.find_template_file(p, cb)
    , callback
  
  find_view_and_layout: (file, request_type, callback) ->
    @find_template file, request_type, (err, template) =>
      return callback(err) if err?
      return callback(null, view: null, layout: null) unless template?
      
      @find_layout template, request_type, (err, layout_template) =>
        return callback(err) if err?
        callback(null, view: template, layout: layout_template)
  
  respond: ->
    file = awesomebox.path.html.join(@req.url)
    request_type = mime.extension(@req.headers.accept) or 'html'
    
    # console.log "REQUEST: #{@req.method} #{@req.url}"
    
    @find_view_and_layout file, request_type, (err, templates) =>
      return @next(err) if err?
      return @next() unless templates.view?
      
      # console.log 'TEMPLATES'
      # console.log " view:   #{templates.view.absolute_path}"
      # console.log " layout: #{templates.layout.absolute_path}"
      
      to_render = [new awesomebox.View(file: templates.view, type: request_type, route: @)]
      to_render.push(new awesomebox.View(file: templates.layout, type: request_type, route: @, parent: to_render[0])) if templates.layout?
      
      async.mapSeries to_render, (v, cb) ->
        v.render(cb)
      , (err, data) =>
        return @next(err) if err?
        
        @res.set('Content-Type': mime.lookup(request_type))
        @res.send(_(data).last())

module.exports = Route
