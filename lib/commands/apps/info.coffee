exports.user_data =
  success_format: 'You have claimed <%= user %> - <%= name %>'

exports.execute = (context, callback) ->
  config = awesomebox.config
  return callback(new Error('No app has been claimed')) unless config?.user? and config?.name?
  
  context.client().app(config.name).get (err, data) ->
    return callback(err) if err?
    callback(null, data)
