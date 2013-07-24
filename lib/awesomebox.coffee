# _ = require 'underscore'
# 
unless global.awesomebox
#   Module = require('module').Module
#   path = process.env.NODE_PATH or ''
#   delimiter = if path.indexOf(':') isnt -1 then ':' else if path.indexOf(';') isnt -1 then ';' else ':'
#   process.env.NODE_PATH = [process.cwd() + '/node_modules', require('path').resolve(__dirname + '/../node_modules'), path].filter((p) -> p isnt '').join(delimiter)
#   Module._initPaths()
#   
  walkabout = require 'walkabout'
  
  awesomebox = global.awesomebox = {
    Logger: require './logger'
    
    root: walkabout(__dirname).join('..')
    path: {
      root: walkabout()
    }
  }
#   
#   if awesomebox.path.root.join('content').exists_sync()
#     awesomebox.path.data = awesomebox.path.root.join('data')
#     awesomebox.path.content = awesomebox.path.root.join('content')
#     awesomebox.path.layouts = awesomebox.path.root.join('layouts')
#   else
#     awesomebox.path.data = awesomebox.path.root.join('data')
#     awesomebox.path.content = awesomebox.path.root
#     awesomebox.path.layouts = awesomebox.path.root.join('layouts')
#   
#   awesomebox.config_file = awesomebox.path.root.join('.awesomebox.json')
#   awesomebox.default_config = require '../templates/default.awesomebox.json'
  awesomebox.logger = new awesomebox.Logger('awesomebox')
  awesomebox.Server = require './server'
  awesomebox.Route = require './route'
  awesomebox.View = require './view'
#   awesomebox.Plugins = require './plugins'
#   
#   awesomebox.commands = require './commands'
# 
# cache = {}
# 
# awesomebox.__defineGetter__ 'is_config_valid', ->
#   config = awesomebox.config
#   config?.user? and config?.name?
# 
# awesomebox.__defineGetter__ 'user', ->
#   awesomebox.config.user
# 
# awesomebox.__defineGetter__ 'name', ->
#   awesomebox.config.name
# 
# awesomebox.__defineGetter__ 'config', ->
#   unless cache.config?
#     try
#       config = awesomebox.config_file.read_file_sync()
#       config = JSON.parse(config)
#       cache.config = _({}).extend(awesomebox.default_config, config)
#     catch e
#       return awesomebox.default_config if e.code is 'ENOENT'
#       awesomebox.logger.error 'An error occurred while parsing your awesomebox.json file'
#       process.exit(1)
#   cache.config
# 
# awesomebox.__defineSetter__ 'config', (config) ->
#   try
#     awesomebox.config_file.write_file_sync(JSON.stringify(config, null, 2))
#     delete cache.config
#   catch e
# 
# awesomebox.__defineGetter__ 'client_config', ->
#   unless cache.client_config?
#     try
#       config = walkabout(process.env.HOME).join('.awesomebox').read_file_sync()
#       cache.client_config = JSON.parse(config)
#     catch e
#       return {}
#   cache.client_config
# 
# awesomebox.__defineSetter__ 'client_config', (config) ->
#   try
#     walkabout(process.env.HOME).join('.awesomebox').write_file_sync(JSON.stringify(config, null, 2))
#     delete cache.client_config
#   catch e
# 
# {spawn} = require 'child_process'
# walkabout = require 'walkabout'
# AWESOMEBOX_PATH = walkabout(__dirname).join('../bin/awesomebox').absolute_path
# 
# awesomebox.spawn = (directory, callback) ->
#   directory = walkabout(directory)
#   proc = spawn(AWESOMEBOX_PATH, ['run'], cwd: directory.absolute_path)
#   on_exit = -> proc?.kill()
#   process.on('exit', on_exit)
#   proc.on 'close', -> process.removeListener('exit', on_exit)
#   
#   rx = /Listening on port ([0-9]+)/
#   logs = ''
#   on_data = (data) ->
#     logs += data.toString()
#     match = rx.exec(logs)
#     if match?
#       callback(null, parseInt(match[1]))
#       proc.stdout.removeListener('data', on_data)
#       logs = null
#   
#   proc.stdout.on('data', on_data)
#   
#   proc

module.exports = global.awesomebox
