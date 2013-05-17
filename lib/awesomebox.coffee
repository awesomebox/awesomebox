_ = require 'underscore'

unless global.awesomebox
  Module = require('module').Module
  path = process.env.NODE_PATH or ''
  delimiter = if path.indexOf(':') isnt -1 then ':' else if path.indexOf(';') isnt -1 then ';' else ':'
  process.env.NODE_PATH = [process.cwd() + '/node_modules', require('path').resolve(__dirname + '/../node_modules'), path].filter((p) -> p isnt '').join(delimiter)
  Module._initPaths()
  
  walkabout = require 'walkabout'
  
  awesomebox = global.awesomebox = {
    Logger: require './logger'
    
    root: walkabout(__dirname).join('..')
    path: {
      root: walkabout()
      data: walkabout('data')
      content: walkabout('content')
      layouts: walkabout('layouts')
    }
  }
  
  awesomebox.config_file = awesomebox.path.root.join('.awesomebox.json')
  awesomebox.default_config = require '../templates/default.awesomebox.json'
  awesomebox.logger = new awesomebox.Logger('awesomebox')
  awesomebox.Server = require './server'
  awesomebox.Route = require './route'
  awesomebox.View = require './view'
  awesomebox.Plugins = require './plugins'
  
  awesomebox.commands = require './commands'

cache = {}

awesomebox.__defineGetter__ 'is_config_valid', ->
  config = awesomebox.config
  config?.user? and config?.name?

awesomebox.__defineGetter__ 'user', ->
  awesomebox.config.user

awesomebox.__defineGetter__ 'name', ->
  awesomebox.config.name

awesomebox.__defineGetter__ 'config', ->
  unless cache.config?
    try
      config = awesomebox.config_file.read_file_sync()
      config = JSON.parse(config)
      cache.config = _({}).extend(awesomebox.default_config, config)
    catch e
      return awesomebox.default_config if e.code is 'ENOENT'
      awesomebox.logger.error 'An error occurred while parsing your awesomebox.json file'
      process.exit(1)
  cache.config

awesomebox.__defineSetter__ 'config', (config) ->
  try
    awesomebox.config_file.write_file_sync(JSON.stringify(config, null, 2))
    delete cache.config
  catch e

awesomebox.__defineGetter__ 'client_config', ->
  unless cache.client_config?
    try
      config = walkabout(process.env.HOME).join('.awesomebox').read_file_sync()
      cache.client_config = JSON.parse(config)
    catch e
      return {}
  cache.client_config

awesomebox.__defineSetter__ 'client_config', (config) ->
  try
    walkabout(process.env.HOME).join('.awesomebox').write_file_sync(JSON.stringify(config, null, 2))
    delete cache.client_config
  catch e

module.exports = global.awesomebox
