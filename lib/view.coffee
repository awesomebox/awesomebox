{EventEmitter} = require 'events'

_ = require 'underscore'
async = require 'async'
cheerio = require 'cheerio'
walkabout = require 'walkabout'
consolidate = require 'consolidate'
liverequire = require './liverequire'

PARTIAL_NUMBER = 1000

class View extends EventEmitter
  @find_template_file: (file, callback) ->
    file = walkabout(file)
    filename = file.filename
    file.directory().readdir (err, files) ->
      if err?
        return callback(err) unless err.code is 'ENOENT'
        return callback()
      f = _(files).find (f) -> f.filename.indexOf(filename) is 0 and (f.filename.length is filename.length or f.filename[filename.length] is '.')
      callback(null, f)
  
  constructor: (@opts = {}) ->
  
  install_engines: (callback) ->
    return callback() unless @opts.engines?.length > 0
    
    not_supported = @opts.engines.filter (e) -> !consolidate[e]?
    return callback(new Error("#{not_supported} view engine(s) are not supported")) unless not_supported.length is 0
    
    liverequire(@opts.engines, callback)
  
  render_through_engines: (callback) ->
    data = @opts.content
    
    async.eachSeries @opts.engines, (engine, cb) =>
      view_data = _(@opts.view_data).clone()
      _(view_data).extend(
        awe: {
          view: @
          route: @opts.route
          content: @content.bind(@)
        }
      )
      
      consolidate[engine].render data, view_data, (err, rendered) ->
        return cb(err) if err?
        data = rendered
        cb()
    , (err) =>
      return callback(err) if err?
      @opts.rendered_content = data
      callback()
  
  fetch_content: (callback) ->
    return callback() if @opts.content?
    
    @opts.file.read_file (err, content) =>
      return callback(err) if err?
      @opts.content = content
      callback()
  
  after_render: (callback) ->
    @opts.$ = cheerio.load(@opts.rendered_content)
    
    awesomebox.Plugins.view.after_render @opts.$, @, (err, $) =>
      return callback(err) if err?
      @opts.$ = $
      @opts.rendered_content = $.html()
      callback()
  
  content: (partial, data) ->
    render_partial = (partial, data) =>
      placeholder = "<[PARTIAL-#{PARTIAL_NUMBER++}]>"
      
      if partial[0] is '/'
        partial_path = awesomebox.path.html.join(partial)
      else
        partial_path = @opts.file.directory().join(partial)
      
      partial_path = partial_path.directory().join('_' + partial_path.filename + '.' + @opts.type)
      
      # Push incomplete view so that parent will wait
      view = new View(type: @opts.type, route: @opts.route, parent: @, placeholder: placeholder, view_data: data)
      @opts.placeholders.push(view)
      
      View.find_template_file partial_path, (err, template) =>
        if err?
          awesomebox.logger.error 'Error in rendering partial ' + template.absolute_path
          console.error err.stack
        
        if err? or !template?
          # override view properties so that it doesn't wait for render
          view.opts.rendered_content = ''
          view.opts.done = true
          view.emit('done')
          return
        
        # Set the view's file before rendering
        view.opts.file = template
        view.render()
      
      placeholder
    
    return render_partial(partial, data) if partial? and typeof partial is 'string'
    
    return '' unless @opts.parent?
    @opts.parent.opts.rendered_content
  
  wait_for_placeholders: (callback) ->
    async.each @opts.placeholders, (p, cb) =>
      return cb() if p.opts.done
      p.on 'done', =>
        @opts.rendered_content = @opts.rendered_content.replace(p.opts.placeholder, p.opts.rendered_content)
        cb()
    , callback
  
  render: (callback) ->
    rfilename = @opts.file.filename.split('.').reverse()
    @opts.engines = rfilename[0...rfilename.indexOf(@opts.type)]
    @opts.placeholders = []
    
    @opts.view_data ?= {}
    
    work = [
      (cb) => @fetch_content(cb)
      (cb) => @install_engines(cb)
      (cb) => @render_through_engines(cb)
      (cb) => @wait_for_placeholders(cb)
      (cb) => @after_render(cb)
    ]
    
    async.series work, (err) =>
      return callback?(err) if err?
      @opts.done = true
      @emit('done')
      callback?(null, @opts.rendered_content)

module.exports = View
