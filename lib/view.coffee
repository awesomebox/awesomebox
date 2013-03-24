async = require 'async'
cheerio = require 'cheerio'
consolidate = require 'consolidate'
liverequire = require './liverequire'

class View
  constructor: (@opts = {}) ->
  
  install_engines: (callback) ->
    return callback() unless @opts.engines?.length > 0
    
    not_supported = @opts.engines.filter (e) -> !consolidate[e]?
    return callback(new Error("#{not_supported} view engine(s) are not supported")) unless not_supported.length is 0
    
    liverequire(@opts.engines, callback)
  
  render_through_engines: (callback) ->
    data = @opts.content
    
    async.eachSeries @opts.engines, (engine, cb) =>
      consolidate[engine].render data, @opts.view_data, (err, rendered) ->
        return cb(err) if err?
        data = rendered
        cb()
    , (err) =>
      return callback(err) if err?
      @opts.rendered_content = data
      @opts.$ = cheerio.load(data)
      callback()
  
  fetch_content: (callback) ->
    return callback() if @opts.content?
    
    @opts.file.read_file (err, content) =>
      return callback(err) if err?
      @opts.content = content
      callback()
  
  after_render: (callback) ->
    awesome.Plugins.view.after_render @opts.$, @, (err, $) =>
      return callback(err) if err?
      @opts.$ = $
      @opts.rendered_content = $.html()
      callback()
  
  content: (partial) ->
    # render_partial = (view, partial) ->
    #   if partial[0] is '/'
    #     partial_path = Awesome.path.html.join(partial)
    #   else
    #     partial_path = view.file.join(partial)
    
    # return render_partial(partial) if partial?
    
    return '' unless @opts.parent?
    @opts.parent.opts.rendered_content
  
  render: (callback) ->
    rfilename = @opts.file.filename.split('.').reverse()
    @opts.engines = rfilename[0...rfilename.indexOf('html')]
    
    @opts.view_data = {
      view: @
      content: @content.bind(@)
    }
    
    work = [
      (cb) => @fetch_content(cb)
      (cb) => @install_engines(cb)
      (cb) => @render_through_engines(cb)
      (cb) => @after_render(cb)
    ]
    
    async.series work, (err) =>
      return callback(err) if err?
      callback(null, @opts.rendered_content)

module.exports = View
