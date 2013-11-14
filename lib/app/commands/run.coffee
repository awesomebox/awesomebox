exports.__default__ = ->
  q = require 'q'
  {nopt} = require 'commandment'
  awesomebox = require '../../awesomebox'
  
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
  
  d = q.defer()
  
  server = new awesomebox.Server(opts)
  server.start()
  .then =>
    @log 'Listening on port', server.address.port
    if opts.open is true
      host = if server.address.address in ['0.0.0.0', '127.0.0.1'] then 'localhost' else server.address.address
      port = server.address.port
      require('open')("http://#{host}:#{port}/")
  .catch (err) =>
    d.reject(err)
    # @error(line) for line in err.stack.split('\n')
    # process.exit(1)
  
  d.promise
