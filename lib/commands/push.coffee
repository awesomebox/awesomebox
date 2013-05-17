crypto = require 'crypto'
walkabout = require 'walkabout'
packager = require '../packager'

create_package = (config, callback) ->
  deployment_file = awesomebox.path.root.join('deploy-' + config.name + '-' + crypto.randomBytes(4).toString('hex') + '.tgz')
  
  awesomebox.logger.log 'Packaging...'
  
  packager.pack(awesomebox.path.root.absolute_path, deployment_file.absolute_path, callback)

exports.execute = (context, callback) ->
  config = awesomebox.config
  return callback(new Error('No app has been claimed')) unless awesomebox.is_config_valid
  
  create_package config, (err, filename) ->
    return callback(err) if err?
    
    awesomebox.logger.log 'Deploying ' + config.name
    
    context.client().app(config.name).update filename, (err, data) ->
      walkabout(filename).unlink_sync()
      callback(err, data)
