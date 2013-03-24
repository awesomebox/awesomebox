exports.run = ->
  async = require 'async'
  
  server = null
  
  async.series [
    (cb) -> awesomebox.Plugins.initialize(cb)
    (cb) -> server = new awesomebox.Server(); cb()
    (cb) -> server.initialize(cb)
    (cb) -> server.configure(cb)
    (cb) -> server.start(cb)
  ], (err) ->
    if err?
      awesomebox.logger.error err.message
      process.exit(1)
    
    awesomebox.logger.log "Listening on port #{server.address.port}"
    require('open') "http://#{server.address.address}:#{server.address.port}"

exports.deploy = ->
  tar = require 'tar'
  zlib = require 'zlib'
  fstream = require 'fstream'
  request = require 'request'
  
  deployment_file = awesomebox.path.root.join('deploy-' + require('crypto').randomBytes(4).toString('hex') + '.tgz')
  
  reader = fstream.Reader(
    type: 'Directory'
    path: awesomebox.path.root.absolute_path
    filter: ->
      @basename isnt 'node_modules'
  )
  
  reader
    .pipe(tar.Pack())
    .pipe(zlib.Gzip())
    .pipe(fstream.Writer(deployment_file.absolute_path))
    .on 'close', ->
      req = request.post('http://localhost:8001')
      req.form().append('file', deployment_file.create_read_stream())
      req.on 'end', ->
        deployment_file.unlink_sync()
        awesomebox.logger.log 'Deployed!'
      req.on 'error', (err) ->
        if err.code is 'ECONNREFUSED'
          deployment_file.unlink_sync()
          awesomebox.logger.error 'Could not connect to deployment server'
        else
          awesomebox.logger.error err.message
