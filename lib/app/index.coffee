path = require 'path'
config = require './config'
errors = require './errors'
Commandment = require 'commandment'
AwesomeboxClient = require 'awesomebox.node'
{chalk} = Commandment

module.exports = commands = new Commandment(name: 'awesomebox', command_dir: path.join(__dirname, 'commands'))
awesomebox_config = config(path.join(require('osenv').home(), '.awesomebox'))

describe_error = (err) ->
  return "Whoa there friend. You should probably login first." if errors.is_unauthorized(err)
  
  if err.code?
    switch err.code
      when 'ENOTFOUND'
        return "I couldn't find the awesomebox server.\nAre you connected to the internet?\nMaybe you're in a cafe that has a shoddy connection. DOH!"
      when 'EHOSTUNREACH'
        return "I couldn't reach the awesomebox server.\nI know where it is, but it's not responding to me.\nDon't you hate when that happens?"
  
  console.log err.stack
  text = err.body?.error
  text ?= err.body
  text ?= err.message
  text ?= JSON.stringify(err, null, 2)
  text

handle_error = (err) ->
  @logger.error('')
  @logger.error(line) for line in describe_error(err).split('\n')
  @logger.error('')

header = ->
  @logger.info 'Welcome to ' + chalk.blue.bold('awesomebox')
  @logger.info 'You are using v' + chalk.cyan(require('../awesomebox').version)

footer = ->
  @logger.info chalk.green.bold('ok')


commands.before_execute (context) ->
  context.awesomebox_config = awesomebox_config
  
  context.client = (auth = {}) ->
    server = context.opts.server or context.awesomebox_config.get('server')
    auth.base_url = server if server?
    
    context.last_client = new AwesomeboxClient(auth)
  
  context.client.keyed = ->
    key = context.awesomebox_config.get('api_key')
    return null unless key?
    context.client(api_key: key)
  
  context.login = (user) ->
    context.awesomebox_config.destroy()
    user.server = context.last_client._rest_options.base_url
    context.awesomebox_config.set(user)
  
  context.logout = ->
    context.awesomebox_config.destroy()

commands.before_execute (context) ->
  header.call(context)
  context.log('')

commands.after_execute (context, err) ->
  handle_error.call(context, err) if err?
  context.log('')
  footer.call(context)
