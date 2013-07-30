chokidar = require 'chokidar'
portfinder = require 'portfinder'
LivereloadServer = require 'tiny-lr'

class Livereload
  constructor: ->
    return new Livereload() unless @ instanceof Livereload
  
  start: (context, callback) ->
    @lr_server = new LivereloadServer()
    
    @watcher = chokidar.watch(process.cwd(), persistent: true)
    
    on_change = (path) =>
      @lr_server.changed(body: {files: [path]})
    
    @watcher
      .on('add', on_change)
      .on('change', on_change)
      .on('unlink', on_change)
      .on('error', (err) -> console.log(err.stack))
    
    portfinder.basePort = 35729
    portfinder.getPort (err, port) =>
      return callback(err) if err?
      
      @lr_server.listen(port)
      callback()
  
  stop: (context, callback) ->
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
  
  view_pipe: ->
    (cmd, done) =>
      $ = cmd.cheerio
      return done() unless $
    
      n = $('body, head').toArray()
      return done() if n.length is 0
    
      $(n[0]).append(@create_snippet())
    
      done()

module.exports = Livereload
