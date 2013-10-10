class Source
  @define: (method) => new @(method)
  
  constructor: (@method) ->
  
  publish_to: (pipeline) ->
    emitter = (cmd) ->
      pipeline.push(cmd)
    
    @method(emitter)

module.exports = Source
