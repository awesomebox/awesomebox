unless global.awesome
  Module = require('module').Module
  path = process.env.NODE_PATH or ''
  delimiter = if path.indexOf(':') isnt -1 then ':' else if path.indexOf(';') isnt -1 then ';' else ':'
  process.env.NODE_PATH = [process.cwd() + '/node_modules', require('path').resolve(__dirname + '/../node_modules'), path].filter((p) -> p isnt '').join(delimiter)
  Module._initPaths()
  
  walkabout = require 'walkabout'
  
  awesome = global.awesome = {
    Logger: require './logger'
    
    path: {
      root: walkabout()
      html: walkabout('html')
      layout: walkabout('layout')
    }
  }
  
  awesome.logger = new awesome.Logger('awesome')
  awesome.Server = require './server'
  awesome.Route = require './route'
  awesome.View = require './view'
  awesome.Plugins = require './plugins'
  
  awesome.commands = require './commands'

module.exports = global.awesome
