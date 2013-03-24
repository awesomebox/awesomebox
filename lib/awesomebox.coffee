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
      html: walkabout('html')
      layout: walkabout('layout')
    }
  }
  
  awesomebox.logger = new awesomebox.Logger('awesomebox')
  awesomebox.Server = require './server'
  awesomebox.Route = require './route'
  awesomebox.View = require './view'
  awesomebox.Plugins = require './plugins'
  
  awesomebox.commands = require './commands'

module.exports = global.awesomebox
