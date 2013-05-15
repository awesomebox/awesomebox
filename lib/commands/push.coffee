tar = require 'tar'
zlib = require 'zlib'
crypto = require 'crypto'
fstream = require 'fstream'
walkabout = require 'walkabout'

create_package = (config, callback) ->
  deployment_file = awesomebox.path.root.join('deploy-' + config.name + '-' + crypto.randomBytes(4).toString('hex') + '.tgz')
  
  reader = fstream.Reader(
    type: 'Directory'
    path: awesomebox.path.root.absolute_path
    filter: -> @basename[0] isnt '.' and @basename not in ['node_modules', 'components']
  )
  
  awesomebox.logger.log 'Packaging app into ' + deployment_file.filename
  
  reader
    .pipe(tar.Pack())
    .pipe(zlib.Gzip())
    .pipe(fstream.Writer(deployment_file.absolute_path))
    .on 'error', (err) ->
      callback(new Error('There was an error in packaging your app'))
    .on 'close', ->
      # awesomebox.logger.log 'Packaging finished'
      callback(null, deployment_file.absolute_path)

exports.execute = (context, callback) ->
  config = awesomebox.config
  return callback(new Error('No app has been claimed')) unless config.user? and config.name?
  
  create_package config, (err, filename) ->
    return callback(err) if err?
    
    awesomebox.logger.log 'Deploying ' + config.name
    
    context.client().app(config.name).update filename, (err, data) ->
      walkabout(filename).unlink_sync()
      callback(err, data)
