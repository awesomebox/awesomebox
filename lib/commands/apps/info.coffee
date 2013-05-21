exports.user_data =
  success_format: 'You have claimed <%= user %> - <%= name %>'

exports.execute = (context, callback) ->
  return callback(new Error('No app has been claimed')) unless awesomebox.is_config_valid
  
  context.client().app(awesomebox.name).get (err, data) ->
    return callback(err) if err?
    callback(null, data)
