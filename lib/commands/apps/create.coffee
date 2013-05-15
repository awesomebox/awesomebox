exports.args = 'app-name'
exports.user_data =
  success_format: 'App <%= user %> - <%= name %> has successfully been created and claimed!'

exports.execute = (context, app_name, callback) ->
  config = awesomebox.config
  return callback(new Error("App #{config.user} - #{config.name} is already claimed, cannot create another in this directory")) if config?.user? and config?.name?
  
  context.client().apps.create app_name, (err, data) ->
    return callback(err) if err?
    
    awesomebox.config = {
      user: data.user
      name: data.name
    }
    callback(null, data)
