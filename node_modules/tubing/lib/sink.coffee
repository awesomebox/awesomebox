class Sink
  @define: (method) => new @(method)
  
  constructor: (@method) ->
    
  process: (context, err, cmd) ->
    @method.call(context, err, cmd)

module.exports = Sink
