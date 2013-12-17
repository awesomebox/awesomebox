q = require 'q'
{chalk} = require 'commandment'
errors = require '../errors'
config = require '../config'
Synchronizer = require '../synchronizer'
SocketSynchronizer = require '../socket_synchronizer'

exports.save = ->
  client = @client.keyed()
  throw errors.unauthorized() unless client?
  
  box_config = config(process.cwd() + '/.awesomebox')
  
  get_box = =>
    box = box_config.get('id', 'name')
    unless box.id? and box.name?
      @log "It doesn't look like you've created a box for this project yet."
      return no_box()
    
    client.box(box.id).get()
    .catch (err) =>
      throw err unless err.status_code is 404
      
      @log "Sorry, it looks like the box for this project no longer exists."
      @log('')
      no_box()
  
  create_box = =>
    @prompt
      name: {prompt: 'name'}
    .then (data) =>
      client.boxes.create(data)
    .then (box) =>
      box_config.set(box)
      
      @log('')
      @log "Great! Now that you've created a box, we'll save your code to it."
      @log('')
      
      box
  
  no_box = =>
    client.boxes.list()
    .then (boxes) =>
      if boxes.length is 0
        @log "Let's fix that. Name your new box."
        @log('')
        return create_box()
      
      @log "Are you saving a box that already exists? Maybe one of these?"
      @log('')
      
      ask_which_box(boxes)
  
  ask_which_box = (boxes) =>
    x = 0
    boxes = boxes.map((b) -> "#{b.owner}/#{b.name}").sort()
    @log "#{++x}) #{b}" for b in boxes
    @log "#{++x}) Create a new box"
    
    @prompt
      box: {prompt: 'box'}
    .then (data) =>
      unless parseInt(data.box).toString() is data.box.toString()
        @error('\nSorry, you must respond with a number\n')
        return ask_which_box(boxes)
      
      data.box = parseInt(data.box)
      unless data.box > 0 and data.box <= boxes.length + 1
        @error("\nThat's not one of the choices... Try again.\n")
        return ask_which_box(boxes)
      
      @log('')
      
      if data.box <= boxes.length
        box = boxes[data.box - 1]
        box_config.set(box)
        return box
      
      @log "OK cool. Let's get that new box setup for you."
      @log('')
      create_box()
  
  # get_message = =>
  #   @log 'Leave a message to remind yourself of the changes you made.'
  #   @log('')
  #   @prompt
  #     message: {prompt: 'message'}
  #   .then (data) =>
  #     @log('')
  #     data.message
  
  save_code_to_box = (box) =>
    @log "Preparing to save #{box.name}..."
    @log('')
    
    synchronizer = new SocketSynchronizer(
      box: box.id
      root: process.cwd()
      log: @log.bind(@)
      prompt: @prompt.bind(@)
      server: @opts.server or @awesomebox_config.get('server')
      api_key: @awesomebox_config.get('api_key')
    )
    
    # synchronizer = new Synchronizer(client)
    # synchronizer.sync
    #   box: box.id
    #   root: process.cwd()
    #   on_progress: @log.bind(@)
    #   collect_metadata: ->
    #     get_message()
    #     .then (message) -> {message: message}
    
    synchronizer.start()
    .then (version) =>
      unless version?
        @log('')
        @log "All of your files are up to date. Horay!"
      else
        @log('')
        @log "All done saving #{box.name}!"
        @log "We've created new version #{chalk.cyan(version.name)} for you."
        @log "You can see it at #{chalk.cyan('http://' + version.domain)}"
  
  get_box()
  .then(save_code_to_box)

exports.load = (box_name, box_version) ->
  @log "We're sorry! #{chalk.cyan('awesomebox load')} isn't ready for action yet."
  @log "For now, go to http://awesomebox.co to download the code for a version."

  return
#   
#   client = @client.keyed()
#   return callback(errors.unauthorized()) unless client?
#   
#   get_box = (name, cb) =>
#     return no_box(cb) unless name?
#     
#     client.box(name).get (err, box) =>
#       return cb(err) if err?
#       return cb(null, box) if box?
#       
#       @log "Hmm, doesn't look like you have a box with that name."
#       @lob('')
#       no_box(cb)
#   
#   no_box = (cb) =>
#     client.boxes.list (err, boxes) =>
#       return cb(err) if err?
#       
#       if boxes.length is 0
#         @log "Doesn't look like you have any boxes to load."
#         return callback()
# 
#       @log "Want to load one of these?"
#       @log('')
#       
#       x = 0
#       @log "#{++x}) #{b.name}" for b in boxes
#       @prompt.get
#         properties:
#           box:
#             required: true
#             type: 'number'
#             conform: (v) ->
#               v > 0 and v <= boxes.length
#       , (err, data) =>
#         return cb(err) if err?
#         
#         @log('')
#         console.log 'got box'
#         cb(null, boxes[data.box - 1])
#   
#   get_version = (box, version, cb) =>
#     console.log 'get_version', arguments
#     return no_version(box, cb) unless version?
#     
#     client.box(box.id).version(version).get (err, box) =>
#       return cb(err) if err?
#       return cb(null, box) if box?
#       
#       @log "Hmm, doesn't look like #{chalk.magenta(box.name)} has that version."
#       @lob('')
#       no_version(box, cb)
#   
#   no_version = (box, cb) =>
#     client.box(box.id).versions.list (err, versions) =>
#       return cb(err) if err?
#       
#       console.log versions
#       
#       if versions.length is 0
#         @log "Doesn't look like #{box.name} has any versions to load."
#         callback()
#       else
#         @log "Want to load one of these?"
#         @log('')
#         
#         x = 0
#         @log "#{++x}) #{v.name}" for v in versions
#         callback()
#         # @prompt.get
#         #   properties:
#         #     box:
#         #       required: true
#         #       type: 'number'
#         #       conform: (v) ->
#         #         v > 0 and v <= boxes.length
#         # , (err, data) =>
#         #   return cb(err) if err?
#         #   
#         #   @log('')
#         #   
#         #   cb(null, boxes[data.box - 1])
#   
#   get_box box_name, (err, box) =>
#     return callback(err) if err?
#     console.log box
#     console.log 'call get_version'
#     get_version box, box_version, (err, version) =>
#       return callback(err) if err?
#       console.log version
#     
#     # Check if current folder is empty
#     # Ask to overwrite
#   
#   # box_config = config(process.cwd() + '/.awesomebox')
#   
# 
# # exports.init = (cb) ->
# #   cfg = config(process.cwd() + '/.awesomebox')
# #   if cfg.get('id')?
# #     @log 'The current directory is already an awesomebox project'
# #     return cb()
# #   
# #   @log 'Initializing current directory as an awesomebox project'
# #   
# #   cfg.set(id: 1)
# #   
# #   cb()
