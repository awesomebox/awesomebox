exports.args = '~version'

exports.execute = (context, version, callback) ->
  return callback(new Error('No app has been claimed')) unless awesomebox.is_config_valid
  
  if typeof version is 'function'
    callback = version
    version = null
  
  if version?
    context.client().app(awesomebox.name).version(version).status(callback)
  else
    context.client().app(awesomebox.name).versions.list(callback)
