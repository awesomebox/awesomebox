async = require 'async'
moment = require 'moment'
walkabout = require 'walkabout'
Awesomebox = require 'awesomebox.node'

client = (email, password) ->
  return new Awesomebox(base_url: process.env.AWESOMEBOX_URL, email: email, password: password) if email? and password?
  config = awesomebox.client_config
  return new Awesomebox(base_url: process.env.AWESOMEBOX_URL) unless config?.api_key?
  new Awesomebox(base_url: process.env.AWESOMEBOX_URL, api_key: config.api_key)

exports.run = (callback) ->
  async = require 'async'
  
  server = new awesomebox.Server()
  
  async.series [
    (cb) -> server.initialize(cb)
    (cb) -> server.configure(cb)
    (cb) -> server.start(cb)
  ], (err) ->
    if err?
      awesomebox.logger.error err.message
      process.exit(1)
    callback()

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
      awesomebox.logger.log 'URL:          ' + JSON.parse(data.spawnWith.env.__AWESOMEBOX_CONFIG__).domain.split(',').map((d) -> "http://#{d}").join('\n                           ')
    else
      awesomebox.logger.log "Not running"
    console.log()
    
    callback(null, data)

exports.status = (callback) ->
  client().app(awesomebox.name).status(print_status(callback))

exports.login = (callback) ->
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
        callback()

exports.logout = (callback) ->
  config = awesomebox.client_config
  delete config.api_key
  awesomebox.client_config = config
  awesomebox.logger.log 'Logged out successfully!'
  callback()

exports.start = (callback) ->
  client().app(awesomebox.name).start(print_status(callback))

exports.stop = (callback) ->
  client().app(awesomebox.name).stop(print_status(callback))

exports.logs = (callback) ->
  client().app(awesomebox.name).logs (err, data) ->
    return print_error(err) if err?
    console.log()
    console.log data
    callback()

exports.domains =
  add: (domain, callback) ->
    client().app(awesomebox.name).domains.add domain, (err, data) ->
      return print_error(err) if err?
      console.log data
      callback()
  remove: (domain, callback) ->
    client().app(awesomebox.name).domains.remove domain, (err, data) ->
      return print_error(err) if err?
      console.log data
      callback()
  list: (callback) ->
    client().app(awesomebox.name).domains.list (err, data) ->
      return print_error(err) if err?
      console.log data
      callback()

print_result = (callback, format) ->
  (err, data) ->
    if err?
      print_error(err)
      return callback(err)
    
    if typeof format is 'function'
      console.log format(data)
    else if typeof format is 'string'
      console.log format
    else if !format?
      console.log data
    
    callback(null, data)

exports.apps =
  list: (cb) -> client().apps.list print_result(cb)
  create: (name, cb) -> client().apps.create name, print_result(cb)
exports.apps.create.command = 'create <name>'

exports.info = (cb) ->
  print_result(cb)(null, awesomebox.config)
