_ = require 'underscore'
mime = require 'mime'
async = require 'async'
walkabout = require 'walkabout'
compiler = require 'connect-compiler'

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
    @req.awesomebox ?= {}
    @req.awesomebox.route = @
  
  find_template: (root, callback) ->
    paths = [root]
    paths.unshift(root.join('index.html')) if root.extension is ''
    
    firstSeries paths, (p, cb) =>
      awesomebox.View.find_template_file(p, cb)
    ,  callback
  
  find_layout: (root, callback) ->
    relative = walkabout(awesomebox.path.layouts.join(require('path').relative(awesomebox.path.content.absolute_path, root.absolute_path)).dirname)
    
    paths = [awesomebox.path.layouts.join('default.html')]
    until relative.absolute_path is awesomebox.path.layouts.absolute_path
      paths.unshift(walkabout(relative.absolute_path + '.html'))
      relative = walkabout(relative.dirname)
    
    firstSeries paths, (p, cb) =>
      awesomebox.View.find_template_file(p, cb)
    , callback
  
  respond: ->
    @request_path = awesomebox.path.content.join(@req.url)
    @request_type = @request_path.extension or 'html'
    
    # console.log "REQUEST: #{@req.method} #{@req.url}"
    
    @find_template @request_path, (err, template) =>
      return @next(err) if err?
      return @next() unless template?
      
      to_render = [new awesomebox.View(file: template, type: @request_type, route: @)]
      
      do_render = =>
        async.mapSeries to_render, (v, cb) ->
          v.render(cb)
        , (err, data) =>
          if err?
            return @next(err) unless err.code in ['EISDIR']
            return @next()
          
          @res.set('Content-Type': mime.lookup(@request_type))
          @res.send(_(data).last())
      
      return do_render() unless @request_type is 'html'
      
      @find_layout template, (err, layout_template) =>
        return @next(err) if err?
        to_render.push(new awesomebox.View(file: layout_template, type: @request_type, route: @, parent: to_render[0])) if layout_template?
        do_render()

module.exports = Route
