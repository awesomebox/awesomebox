exports.args = '~app-name'
exports.user_data =
  success_format: 'App <%= user %> - <%= name %> has successfully been created and claimed!'

exports.execute = (context, app_name, callback) ->
  if typeof app_name is 'function'
    callback = app_name
    app_name = awesomebox.path.root.filename
  
  return callback(new Error("App #{awesomebox.user} - #{awesomebox.name} is already claimed, cannot create another in this directory")) if awesomebox.is_config_valid
  
  context.client().apps.create app_name, (err, data) ->
    return callback(err) if err?
    
    awesomebox.config = {
      user: data.user
      name: data.name
    }
    callback(null, data)
