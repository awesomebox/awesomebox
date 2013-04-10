{Module} = require 'module'
{EventEmitter} = require 'events'

_ = require 'underscore'
async = require 'async'
cheerio = require 'cheerio'
walkabout = require 'walkabout'
consolidate = require 'consolidate'
liverequire = require './liverequire'

PARTIAL_NUMBER = 1000


consolidate_render = (engine) ->
  (data, view, callback) ->
    view_data = _(view.opts.view_data).clone()
    _(view_data).extend(
      box: {
        view: view
        route: view.opts.route
        content: view.content.bind(view)
        data: view.data.bind(view)
      }
    )
  
    consolidate[engine].render(data, view_data, callback)

# Need to add stylus, sass, scss

ENGINES =
  coffee:
    require: 'coffee-script'
    process: (data, view, callback) ->
      try
        callback(null, require('coffee-script').compile(data, bare: true))
      catch e
        callback(e)
  
  less:
    require: 'recess'
    process: (data, view, callback) ->
      Recess = require('recess').Constructor
      instance = new Recess()
      instance.options.compile = true
      # instance.options.compress = true
      instance.path = view.opts.file.absolute_path
      instance.data = data
      instance.callback = ->
        if instance.errors.length > 0
          return callback(instance.errors[0])
        callback(null, instance.output.join('\n'))
      
      instance.parse()

for k in Object.keys(consolidate) when k isnt 'clearCache'
  ENGINES[k] = 
    require: k
    process: consolidate_render(k)

console.log ENGINES

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
  
  @find_template_file_sync: (file) ->
    file = walkabout(file)
    filename = file.filename
    try
      files = file.directory().readdir_sync()
      _(files).find (f) -> f.filename.indexOf(filename) is 0 and (f.filename.length is filename.length or f.filename[filename.length] is '.')
    catch err
      null
  
  constructor: (@opts = {}) ->
    awesomebox.Plugins.wrap(@,
      'view.render': 'do_render'
    )
  
  fetch_content: (callback) ->
    return callback() if @opts.content?

    @opts.file.read_file (err, content) =>
      return callback(err) if err?
      @opts.content = content
      callback()
  
  install_engines: (callback) ->
    return callback() unless @opts.engines?.length > 0
    
    not_supported = @opts.engines.filter (e) -> !ENGINES[e]?
    return callback(new Error("#{not_supported} view engine(s) are not supported")) unless not_supported.length is 0
    
    # console.log 'requiring ' + require('util').inspect(@opts.engines)
    liverequire(@opts.engines.map((e) -> ENGINES[e].require), callback)
  
  render_through_engines: (callback) ->
    data = @opts.content
    
    async.eachSeries @opts.engines, (engine, cb) =>
      ENGINES[engine].process data, @, (err, rendered) ->
        return cb(err) if err?
        data = rendered
        cb()
    , (err) =>
      return callback(err) if err?
      @opts.rendered_content = data
      callback()
  
  load_cheerio: (callback) ->
    if @opts.type is 'html'
      @opts.$ = cheerio.load(@opts.rendered_content)
    callback()
  
  data: (path) ->
    # make it so we can load xml, yml, json, etc...
    # try to load remote sources too...
    
    data_path = awesomebox.path.data.join(path)
    data_file = View.find_template_file_sync(data_path)
    unless data_file?
      awesomebox.logger.error 'No data file at ' + path
      return {}
    try
      delete Module._cache[data_file.absolute_path]
      require(data_file.absolute_path)
    catch err
      awesomebox.logger.error 'Error in parsing data file ' + path
      console.error err.stack
      {}
  
  content: (partial, data) ->
    render_partial = (partial, data) =>
      placeholder = "<[PARTIAL-#{PARTIAL_NUMBER++}]>"
      
      if partial[0] is '/'
        partial_path = awesomebox.path.content.join(partial)
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
  
  do_render: (callback) ->
    async.series [
      (cb) => @fetch_content(cb)
      (cb) => @install_engines(cb)
      (cb) => @render_through_engines(cb)
      (cb) => @wait_for_placeholders(cb)
      # (cb) => @after_render(cb)
      (cb) => @load_cheerio(cb)
    ], callback
  
  render: (callback) ->
    rfilename = @opts.file.filename.split('.').reverse()
    @opts.engines = rfilename[0...rfilename.indexOf(@opts.type)]
    @opts.placeholders = []
    @opts.view_data ?= {}
    
    @do_render (err) =>
      return callback?(err) if err?
      @opts.rendered_content = @opts.$.html() if @opts.$?
      @opts.done = true
      @emit('done')
      callback?(null, @opts.rendered_content)

module.exports = View
