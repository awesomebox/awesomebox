mime = require 'mime'
walkabout = require 'walkabout'
{ViewPipeline, HttpSink} = require './view_pipeline'

debug = require('debug')('awesomebox:route')

class Route
  constructor: (@req, @res, @next) ->
  
  respond: ->
    root = walkabout()
    content_exists = root.join('content').exists_sync()
    
    pipeline = ViewPipeline.configure(
      path:
        content: if content_exists then root.join('content') else root
        layouts: root.join('layouts')
        data: root.join('data')
      
      enable_layouts: content_exists
      enable_data: content_exists
    )
    
    pipeline.publish_to(HttpSink)
    
    pipeline.push(
      req: @req
      res: @res
      next: @next
    )

module.exports = Route
