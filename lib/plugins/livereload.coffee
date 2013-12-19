q = require 'q'
chokidar = require 'chokidar'
portfinder = require 'portfinder'
LivereloadServer = require 'tiny-lr'

class Livereload
  constructor: (server) ->
    return new Livereload(server) unless @ instanceof Livereload
    @server = server
  
  install: ->
    @server.router.renderer.steps['post-process'].insert(
      {livereload: @insert_script.bind(@)}
      {before: 'extract-from-cheerio'}
    )
    
    @server.router.template_renderer.steps['post-process'].insert(
      {livereload: @insert_script.bind(@)}
      {before: 'extract-from-cheerio'}
    )
  
  start: ->
    @lr_server = new LivereloadServer()
    
    @watcher = chokidar.watch(process.cwd(), persistent: true)
    
    on_change = (path) =>
      @server.router.tree.invalidate(path)
      @lr_server.changed(body: {files: [path]})
    
    @watcher
      .on('add', on_change)
      .on('change', on_change)
      .on('unlink', on_change)
      .on('error', (err) -> console.log(err.stack))
    
    portfinder.basePort = 35729
    q.ninvoke(portfinder, 'getPort')
    .then (port) =>
      @lr_server.listen(port)
  
  stop: ->
    # @gaze.close()
    @watcher.close()
    @lr_server.close()
  
  create_snippet: ->
    '''
    <!-- livereload snipped -->
    <script>
      document.write('<script src="http://' + (location.host || 'localhost').split(':')[0] + ':#{port}/livereload.js?snipver=1"><\\/script>');
    </script>
    '''.replace('#{port}', @lr_server.port)
  
  insert_script: (opts) ->
    n = opts.$('body, head').toArray()
    return if n.length is 0
  
    opts.$(n[0]).append(@create_snippet())

module.exports = Livereload
