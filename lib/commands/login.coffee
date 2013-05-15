Prompt = require '../prompt'

exports.execute = (context, callback) ->
  prompt = new Prompt(awesomebox.logger.prompt)
  
  prompt.ask_for 'Email Address: ', (email) ->
    prompt.ask_for 'Password: ', {password: true}, (password) ->
      context.client(email, password).user.get (err, user) ->
        return callback(new Error('The email or password you entered is incorrect')) if err?
        config = awesomebox.client_config
        config.api_key = user.api_key
        awesomebox.client_config = config
        callback(null, 'Logged in successfully!')
