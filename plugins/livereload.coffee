{Gaze} = require 'gaze'
LivereloadServer = require 'tiny-lr'

create_snippet = (port = 35729) ->
  '''
  <!-- livereload snipped -->
  <script>
    document.write('<script src="http://' + (location.host || 'localhost').split(':')[0] + ':#{port}/livereload.js?snipver=1"><\\/script>');
  </script>
  '''.replace('#{port}', port)

module.exports = (context, done) ->
  context.on 'post:server.initialize', (server, args, results, next) ->
    server.lr_server = new LivereloadServer()
    
    server.gaze = new Gaze(['content/**', 'layouts/**', 'data/**'])
    server.gaze.on 'changed', (path) -> server.lr_server.changed(body:{files: [path]})
    
    next()
  
  context.on 'post:server.start', (server, args, results, next) ->
    server.lr_server.listen(35729, next)
  
  context.on 'post:server.stop', (server, args, results, next) ->
    server.gaze.close()
    server.lr_server.close()
    next()
  
  context.on 'post:view.render', (view, args, results, next) ->
    if view.opts.$?
      $node = view.opts.$('head')
      $node = view.opts.$.root() if $node.length is 0
      $node.append(create_snippet())
    next()
  
  done()
