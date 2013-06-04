exports.args = 'app-name'
exports.user_data =
  success_format: 'App <%= user %> - <%= name %> has successfully been claimed!'

exports.opts = {
  'force': 'f'
}

exports.execute = (context, app_name, callback) ->
  return callback(new Error("App #{awesomebox.user} - #{awesomebox.name} is already claimed")) if awesomebox.is_config_valid
  
  context.client().app(app_name).get (err, data) ->
    return callback(err) if err?
    
    awesomebox.config = {
      user: data.user
      name: data.name
    }
    callback(null, data)
