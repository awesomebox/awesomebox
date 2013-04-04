async = require 'async'
moment = require 'moment'
walkabout = require 'walkabout'
Awesomebox = require 'awesomebox.node'

client = (email, password) ->
  return new Awesomebox(email: email, password: password) if email? and password?
  config = awesomebox.client_config
  return new Awesomebox() unless config?.api_key?
  new Awesomebox(api_key: config.api_key)



exports.run = ->
  async = require 'async'
  
  server = null
  
  async.series [
    # (cb) -> awesomebox.Plugins.initialize(cb)
    (cb) -> server = new awesomebox.Server(); cb()
    (cb) -> server.initialize(cb)
    (cb) -> server.configure(cb)
    (cb) -> server.start(cb)
  ], (err) ->
    if err?
      awesomebox.logger.error err.message
      process.exit(1)

exports.run.description = 'Run!'

exports.package = (callback) ->
  tar = require 'tar'
  zlib = require 'zlib'
  fstream = require 'fstream'
  name = awesomebox.name
  
  deployment_file = awesomebox.path.root.join('deploy-' + name + '-' + require('crypto').randomBytes(4).toString('hex') + '.tgz')
  
  reader = fstream.Reader(
    type: 'Directory'
    path: awesomebox.path.root.absolute_path
    filter: -> @basename[0] isnt '.' and @basename not in ['node_modules', 'components']
  )
  
  awesomebox.logger.log 'Packaging app into ' + deployment_file.filename
  
  reader
    .pipe(tar.Pack())
    .pipe(zlib.Gzip())
    .pipe(fstream.Writer(deployment_file.absolute_path))
    .on 'error', (err) ->
      awesomebox.logger.error 'There was an error in packaging your app'
      console.log err.stack
      callback?(err)
    .on 'close', ->
      awesomebox.logger.log 'Packaging finished'
      callback?(null, deployment_file.absolute_path)

exports.deploy = (callback) ->
  name = awesomebox.name
  walkabout = require 'walkabout'
  
  exports.package (err, filename) ->
    return if err?
    
    awesomebox.logger.log 'Deploying ' + name
    
    client().app(name).update filename, (err, data) ->
      walkabout(filename).unlink_sync()
      print_status(callback)(err, data)

print_error = (err) ->
  return awesomebox.logger.error('Could not connect to deployment server') if err.code is 'ECONNREFUSED'
  return awesomebox.logger.error('You must log in first') if err.status_code is 401
  return awesomebox.logger.error("App #{awesomebox.name} does not exist") if err.status_code is 404
  awesomebox.logger.error(err.body)

print_status = (callback) ->
  (err, data) ->
    if err?
      print_error(err)
      return callback(err)
  
    console.log()
    awesomebox.logger.log "User:         #{data.user}"
    awesomebox.logger.log "Application:  #{data.app}"
    if data.running
      awesomebox.logger.log "Running for:  #{moment(data.ctime).fromNow(true)}"
      awesomebox.logger.log "URL:          http://#{JSON.parse(data.spawnWith.env.__AWESOMEBOX_CONFIG__).domain}"
    else
      awesomebox.logger.log "Not running"
    console.log()
    
    callback(null, data)

exports.status = (callback) ->
  client().app(awesomebox.name).status(print_status(callback))

exports.login = ->
  Prompt = require './prompt'
  prompt = new Prompt(awesomebox.logger.prompt)
  
  prompt.ask_for 'Email Address: ', (email) ->
    prompt.ask_for 'Password: ', {password: true}, (password) ->
      client(email, password).user.get (err, user) ->
        return awesomebox.logger.error('Incorrect email/password combo') if err?
        config = awesomebox.client_config
        config.api_key = user.api_key
        awesomebox.client_config = config
        awesomebox.logger.log 'Logged in successfully!'

exports.logout = ->
  config = awesomebox.client_config
  delete config.api_key
  awesomebox.client_config = config
  awesomebox.logger.log 'Logged out successfully!'

exports.start = (callback) ->
  client().app(awesomebox.name).start(print_status(callback))

exports.stop = (callback) ->
  client().app(awesomebox.name).stop(print_status(callback))

exports.logs = ->
  client().app(awesomebox.name).logs (err, data) ->
    return print_error(err) if err?
    console.log()
    console.log data
