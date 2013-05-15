exports.execute = (context, callback) ->
  config = awesomebox.client_config
  delete config.api_key
  awesomebox.client_config = config
  callback(null, 'Logged out successfully!')
