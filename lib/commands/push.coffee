crypto = require 'crypto'
walkabout = require 'walkabout'
packager = require '../packager'

create_package = (callback) ->
  deployment_file = awesomebox.path.root.join('deploy-' + awesomebox.name + '-' + crypto.randomBytes(4).toString('hex') + '.tgz')
  
  awesomebox.logger.log 'Packaging...'
  
  packager.pack(awesomebox.path.root.absolute_path, deployment_file.absolute_path, callback)

exports.execute = (context, callback) ->
  return callback(new Error('No app has been claimed')) unless awesomebox.is_config_valid
  
  create_package (err, filename) ->
    return callback(err) if err?
    
    awesomebox.logger.log 'Deploying ' + awesomebox.name
    
    context.client().app(awesomebox.name).update filename, (err, data) ->
      walkabout(filename).unlink_sync()
      callback(err, data)
