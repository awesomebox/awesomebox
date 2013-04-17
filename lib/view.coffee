Path = require 'path'
{Module} = require 'module'
{EventEmitter} = require 'events'

_ = require 'underscore'
async = require 'async'
cheerio = require 'cheerio'
walkabout = require 'walkabout'
consolidate = require 'consolidate'
liverequire = require './liverequire'

PARTIAL_NUMBER = 1000


PARSERS =
  json:
    parse: (data) -> JSON.parse(data)
  yml:
    parse: (data) -> require('js-yaml').load(data)
  yaml:
    parse: (data) -> require('js-yaml').load(data)

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
      awesomebox: null
    )
    view_data.box.data.raw = view.raw_data.bind(view)
    
    consolidate[engine].render(data, view_data, callback)
    

ENGINES =
  coffee:
    require: 'coffee-script'
    process: (data, view, callback) ->
      try
        callback(null, require('coffee-script').compile(data, bare: true))
      catch e
        callback(e)
  
  sass:
    require: 'sass'
    process: (data, view, callback) ->
      try
        callback(null, require('sass').render(data))
      catch err
        callback(err)
  
  scss:
    require: 'sass'
    process: (data, view, callback) ->
      try
        callback(null, require('sass').render(data))
      catch err
        callback(err)
  
  styl:
    require: 'stylus'
    process: (data, view, callback) ->
      stylus.render(data, {filename: view.opts.file.absolute_path}, callback)
  
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
  
  @find_layout_file: (file, callback) ->
    
    
    find_layout: (root, callback) ->
      relative = walkabout(awesomebox.path.layouts.join(require('path').relative(awesomebox.path.content.absolute_path, root.absolute_path)).dirname)

      paths = [awesomebox.path.layouts.join('default.html')]
      until relative.absolute_path is awesomebox.path.layouts.absolute_path
        paths.unshift(walkabout(relative.absolute_path + '.html'))
        relative = walkabout(relative.dirname)

      firstSeries paths, (p, cb) =>
        awesomebox.View.find_template_file(p, cb)
      , callback
  
  constructor: (@opts = {}) ->
    @opts.route.view = @ unless @opts.parent?
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
    if !data_file? or require('path').relative(awesomebox.path.data.absolute_path, data_file.absolute_path).indexOf('..') isnt -1
      awesomebox.logger.error 'No data file at ' + path
      return null
    
    data = data_file.read_file_sync()
    
    parser = PARSERS[data_file.extension]
    return data unless parser?
    
    try
      parser.parse(data)
    catch err
      awesomebox.logger.error 'Error in parsing data file ' + path
      awesomebox.logger.error err.stack
      null
  
  raw_data: (path) ->
    data_path = awesomebox.path.data.join(path)
    data_file = View.find_template_file_sync(data_path)
    return data_file.read_file_sync() if data_file? and require('path').relative(awesomebox.path.data.absolute_path, data_file.absolute_path).indexOf('..') is -1
    
    awesomebox.logger.error 'No data file at ' + path
    null
  
  content: (partial, data) ->
    render_partial = (partial, data) =>
      placeholder = "<[PARTIAL-#{PARTIAL_NUMBER++}]>"
      
      if partial[0] is '/'
        partial_path = awesomebox.path.content.join(partial)
      else
        partial_path = @opts.file.directory().join(partial)
      
      partial_path = partial_path.directory().join('_' + partial_path.filename + '.' + @opts.type)
      
      if require('path').relative(awesomebox.path.content.absolute_path, partial_path.absolute_path).indexOf('..') isnt -1
        awesomebox.logger.error 'No content file at ' + partial_path.path
        return ''
      
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
        # If data was a string, fetch the data file before render
        view.opts.view_data = @data(view.opts.view_data) if typeof view.opts.view_data is 'string'
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
  
  @configure: (opts) ->
    {
      render: (o, callback) =>
        if typeof o is 'function'
          callback = o
          o = {}
        @render(_(o).extend(opts), callback)
    }
  
  @render: (opts, callback) ->
    if typeof opts is 'function'
      callback = opts
      opts = {}
    
    opts.view_root = if opts.view_root? then walkabout(opts.view_root) else walkabout('views')
    opts.layout_root = if opts.layout_root? then walkabout(opts.layout_root) else opts.view_root.join('layouts')
    opts.layout_default_root ?= 'default'
    opts.layout_default_root.replace(/\.+/, '')
    opts.use_layouts ?= false
    opts.path ?= ''
    opts.path = [opts.path] unless Array.isArray(opts.path)
    
    opts.extra = _(opts).omit('view_root', 'layout_root', 'use_layouts', 'layout_default_root', 'path', 'parent', 'view_data')
    opts = _(opts).omit(_(opts.extra).keys())
    
    opts.view_path = opts.path[0]
    opts.view_type = Path.extname(opts.path[0]).replace(/^\.+/, '') or 'html'
    
    firstSeries opts.path.map((p) -> opts.view_root.join(p)), @find_template_file,  (err, template) =>
      return callback(err) if err?
      return callback() unless template?
      
      opts.view_template = template
      opts.views = [new @(_({}).extend(opts.extra, {file: template, type: opts.view_type}))]
      
      do_render = ->
        async.mapSeries opts.views, (v, cb) ->
          v.render(cb)
        , (err, data) ->
          return callback(err) if err?
          callback(null, _(data).last(), opts)
      
      return do_render() unless opts.use_layouts is true
      
      if opts.layout_path?
        opts.layout_path = [opts.layout_path] unless Array.isArray(opts.layout_path)
      else
        relative = opts.layout_root.join(Path.relative(opts.view_root.absolute_path, opts.view_template.absolute_path)).directory()
        opts.layout_path = [opts.layout_root.join(opts.layout_default_root + '.' + opts.view_type)]
        until relative.absolute_path is opts.layout_root.absolute_path
          opts.layout_path.unshift(walkabout(relative.absolute_path + '.' + opts.view_type))
          relative = relative.directory()
      
      firstSeries opts.layout_path, @find_template_file, (err, layout_template) =>
        return callback(err) if err?
        if layout_template?
          opts.layout_template = layout_template
          opts.views.push(new @(_({}).extend(opts.extra ,file: layout_template, type: opts.view_type, parent: opts.views[0])))
        do_render()

module.exports = View
