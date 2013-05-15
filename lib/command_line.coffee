ejs = require 'ejs'
awesomebox = require './awesomebox'
Commandment = require '../commandment'
AwesomeboxClient = require 'awesomebox.node'

commandment = new Commandment('awesomebox', require('../package').version)
commandment.parse(__dirname + '/commands')

commandment.on_error = (err) ->
  return awesomebox.logger.error('Could not connect to deployment server') if err.code is 'ECONNREFUSED'
  return awesomebox.logger.error('You must log in first') if err.status_code is 401
  return awesomebox.logger.error("App #{awesomebox.name} does not exist") if err.status_code is 404
  awesomebox.logger.error(err.body?.error or err.body or err.message)

commandment.on_success = (data, node) ->
  if node.user_data?.success_format?
    data = {data: data} if typeof data is 'string' or Array.isArray(data)
    return awesomebox.logger.success(ejs.render(node.user_data.success_format, data))
  return awesomebox.logger.success(data) if typeof data is 'string'
  awesomebox.logger.success(require('util').inspect(data)) if data?

commandment.context =
  client: (email, password) ->
    return new AwesomeboxClient(base_url: process.env.AWESOMEBOX_URL, email: email, password: password) if email? and password?
    config = awesomebox.client_config
    return new AwesomeboxClient(base_url: process.env.AWESOMEBOX_URL) unless config?.api_key?
    new AwesomeboxClient(base_url: process.env.AWESOMEBOX_URL, api_key: config.api_key)


# console.log require('eyes').inspect(commandment.root)
# commandment.help()

awesomebox.Plugins.initialize ->
  commandment.execute(process.argv.slice(2))
