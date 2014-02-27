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
      console.log err.stack
      throw new Error('Could not parse config file: ', err.message)
    
  constructor: (@root, @filename, @data) ->
    @data.config ?= {}
    
    @plugins = []
    @_read_plugins(@data.plugins) if @data.plugins?
  
  _read_plugins: (plugin_config = {}) ->
    plugin_config.root ?= 'plugins'
    plugin_config.order ?= []
    console.log '[Plugins] Loading from', plugin_config.root
    
    root = path.join(@root, plugin_config.root)
    
    files = fs.readdirSync(root).map (f) ->
      {
        path: path.join(root, f)
        name: f.replace(/\.[^\.]+$/, '')
      }
    .reduce (o, f) ->
      o[f.name] = f
      o
    , {}
    
    ordered_files = []
    for name in plugin_config.order
      if files[name]?
        ordered_files.push(files[name])
        delete files[name]
    ordered_files.push(f) for name, f of files
    
    for file in ordered_files
      try
        console.log '[Plugins] Loading', file.name
        @plugins.push(require file.path)
      catch err
        console.log '[Plugins] ERROR: Could not load plugin: ', file.name, '\n'
        console.log err.stack
  
  get: (key, opts = {}) ->
    a = @data
    a = a?[k] for k in key.split('.')
    a or= opts.default if opts.default?
    a

module.exports = Config
