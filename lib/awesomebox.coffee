unless global.awesomebox
  Module = require('module').Module
  path = process.env.NODE_PATH or ''
  delimiter = if path.indexOf(':') isnt -1 then ':' else if path.indexOf(';') isnt -1 then ';' else ':'
  process.env.NODE_PATH = [process.cwd() + '/node_modules', require('path').resolve(__dirname + '/../node_modules'), path].filter((p) -> p isnt '').join(delimiter)
  Module._initPaths()
  
  walkabout = require 'walkabout'
  
  awesomebox = global.awesomebox = {
    Logger: require './logger'
    
    path: {
      root: walkabout()
      data: walkabout('data')
      content: walkabout('content')
      layouts: walkabout('layouts')
    }
  }
  
  awesomebox.logger = new awesomebox.Logger('awesomebox')
  awesomebox.Server = require './server'
  awesomebox.Route = require './route'
  awesomebox.View = require './view'
  awesomebox.Plugins = require './plugins'
  
  awesomebox.commands = require './commands'

awesomebox.__defineGetter__ 'name', ->
  awesomebox.config.name ? awesomebox.path.root.filename

awesomebox.__defineGetter__ 'config', ->
  try
    config = awesomebox.path.root.join('awesomebox.json').read_file_sync()
    JSON.parse(config)
  catch e
    return {} if e.code is 'ENOENT'
    awesomebox.logger.error 'An error occurred while parsing your awesomebox.json file'
    process.exit(1)

awesomebox.__defineSetter__ 'config', (config) ->
  try
    awesomebox.path.root.join('awesomebox.json').writefile_sync(JSON.stringify(config, null, 2))
  catch e

awesomebox.__defineGetter__ 'client_config', ->
  try
    config = walkabout(process.env.HOME).join('.awesomebox').read_file_sync()
    JSON.parse(config)
  catch e
    {}

awesomebox.__defineSetter__ 'client_config', (config) ->
  try
    walkabout(process.env.HOME).join('.awesomebox').write_file_sync(JSON.stringify(config, null, 2))
  catch e

module.exports = global.awesomebox
