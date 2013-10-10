fs = require 'fs'
nopt = require 'nopt'
path = require 'path'
async = require 'async'
chalk = require 'chalk'
prompt = require 'prompt'
winston = require 'winston'

winston.cli()

levels = {}
levels[k] = v for k, v of winston.config.cli.levels
colors = {}
colors[k] = v for k, v of winston.config.cli.colors

logger = new winston.Logger(transports: [new (winston.transports.Console)()])
logger.cli()


class Commandment
  constructor: (opts) ->
    @_properties = {}
    @name = opts.name
    if opts.command_dir?
      @commands = {}
      for file in fs.readdirSync(opts.command_dir) when !(file[0] in ['.', '_'])
        for k, v of require(path.join(opts.command_dir, file))
          @commands[k] = v
    
    @commands ?= opts.commands
    
    @filters =
      before: []
      after: []
  
  _parse_args: (argv) ->
    opts = nopt(argv)
    args = Array::slice.call(opts.argv.remain)
    delete opts.argv
    
    data =
      opts: opts
    
    return data unless args.length > 0

    data.name = args.shift()
    data.args = args
    data.command = @commands[data.name]
    
    data
  
  _before_execute: (context, callback) ->
    async.eachSeries @filters.before, (filter, cb) ->
      filter(context, cb)
    , callback
  
  _after_execute: (context, err, callback) ->
    async.eachSeries @filters.after, (filter, cb) ->
      filter(context, err, cb)
    , callback
  
  _execute_command: (data, callback) ->
    {name, args, opts, command} = data
    
    unless levels[name]?
      levels[name] = 10
      colors[name] = 'magenta'
      logger.setLevels(levels)
      winston.addColors(colors)
    
    prompt.message = chalk[colors[name]](name)
    prompt.start()
    
    context =
      command: name
      params: args or []
      opts: opts
      properties: @_properties
      get: @get.bind(@)
      set: =>
        @set(arguments...)
        context
      
      log: logger.log.bind(logger, name)
      error: logger.error.bind(logger)
      logger: logger
      prompt: prompt
    
    @_before_execute context, (err) =>
      command.apply context, context.params.concat (err) =>
        @_after_execute context, err, (err) =>
          callback?(err)
  
  before_execute: (cb) ->
    @filters.before.push(cb)
    @

  after_execute: (cb) ->
    @filters.after.push(cb)
    @
  
  get: (key) ->
    @_properties[key]
  
  set: (vals) ->
    @_properties[k] = v for k, v of vals
    @
  
  execute: (argv) ->
    data = @_parse_args(argv)
    callback = -> process.exit(0)
    
    return @_execute_command(data, callback) if data.command?
    return @_execute_command(name: 'help', opts: data.opts, command: @commands.help, callback) if (data.name? and @commands.help?) or (!data.name? and !@commands.__default__?)
    return @_execute_command(name: @name, opts: data.opts, command: @commands.__default__, callback) if !data.name? and @commands.__default__?
    process.exit(1)

module.exports = Commandment
