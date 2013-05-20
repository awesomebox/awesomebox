exports.args = 'version'
exports.hidden = true

exports.execute = (context, version, callback) ->
  return callback(new Error('No app has been claimed')) unless awesomebox.is_config_valid
  
  context.client().app(awesomebox.name).version(version).logs(callback)
