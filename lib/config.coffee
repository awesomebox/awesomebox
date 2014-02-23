fs = require 'fs'
vm = require 'vm'
path = require 'path'

class Config
  @load: (root_dir) ->
    filename = if fs.existsSync(path.join(root_dir, 'awesomebox.json'))
      'awesomebox.json'
    else if fs.existsSync(path.join(root_dir, '_awesomebox.json'))
      '_awesomebox.json'
    
    try
      content = if filename? then fs.readFileSync(path.join(root_dir, filename)).toString() else '{}'
      
      sandbox = {process: process}
      vm.runInNewContext("this.config = #{content};", sandbox, filename)
      
      new Config(root_dir, filename or '_awesomebox.json', sandbox.config)
    catch err
      throw new Error('Could not parse config file: ', err.message)
    
  constructor: (@root, @filename, @data) ->
    @data.config ?= {}
    
    @plugins = []
    @_read_plugins(path.join(@root, @data.plugin_root)) if @data.plugin_root?
  
  _read_plugins: (root) ->
    console.log 'Reading plugins from', root
    for file in fs.readdirSync(root)
      try
        @plugins.push(require path.join(root, file))
      catch err
        console.log 'ERROR: Could not load plugin: ', file, '\n'
        console.log err.stack
  
  get: (key, opts = {}) ->
    a = @data
    a = a?[k] for k in key.split('.')
    a or= opts.default if opts.default?
    a

module.exports = Config
