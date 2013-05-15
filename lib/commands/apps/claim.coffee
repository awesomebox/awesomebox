exports.args = 'app-name'
exports.user_data =
  success_format: 'App <%= data.user %> - <%= name %> has successfully been claimed!'

exports.opts = {
  'force': 'f'
}

exports.execute = (context, app_name, callback) ->
  config = awesomebox.config
  return callback(new Error("App #{config.user} - #{config.name} is already claimed")) if config?.user? and config?.name?
  
  context.client().app(app_name).get (err, data) ->
    return callback(err) if err?
    
    awesomebox.config = {
      user: data.user
      name: data.name
    }
    callback(null, data)
