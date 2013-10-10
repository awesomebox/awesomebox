async = require 'async'
nopt = require 'commandment/node_modules/nopt'

exports.__default__ = (cb) ->
  awesomebox = @get('awesomebox')
  
  opts = nopt(
    watch: Boolean
    'hunt-port': Boolean
    port: Number
    open: Boolean
  ,
    p: '--port'
  , process.argv)
  
  opts.watch ?= true
  opts['hunt-port'] ?= true
  opts.port ?= Number(process.env.PORT) if process.env.PORT?
  opts.open ?= true
  
  server = new awesomebox.Server(opts)
  
  async.series [
    (cb) -> server.initialize(cb)
    (cb) -> server.configure(cb)
    (cb) -> server.start(cb)
  ], (err) =>
    if err?
      console.log err.stack
      process.exit(1)
    
    @log 'Listening on port', server.address.port
    if opts.open is true
      host = if server.address.address in ['0.0.0.0', '127.0.0.1'] then 'localhost' else server.address.address
      port = server.address.port
      require('open')("http://#{host}:#{port}/")
