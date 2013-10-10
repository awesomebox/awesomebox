chalk = require 'chalk'
moment = require 'moment'
config = require '../config'

exports.boxes = (callback) ->
  client = @client.keyed()
  return callback(errors.unauthorized()) unless client?
  
  client.boxes.list (err, boxes) =>
    return callback(err) if err?
    @log(line) for line in JSON.stringify(boxes, null, 2).split('\n')
  
    callback()

exports.versions = (box, callback) ->
  client = @client.keyed()
  return callback(errors.unauthorized()) unless client?
  
  if typeof box is 'function'
    callback = box
    box_config = config(process.cwd() + '/.awesomebox')
    return callback(new Error('Please specify a box name')) unless box_config.get('id')?
    box = box_config.get('id')
  
  client.box(box).versions.list (err, versions) =>
    return callback(err) if err?
    
    versions = versions.sort (lhs, rhs) -> lhs.number > rhs.number
    
    for x in [0...versions.length]
      v = versions[x]
      
      msg = v.message
      lines = [msg.slice(0, 60)]
      lines.push(msg.slice(0, 60)) while (msg = msg.slice(60)) isnt ''
      
      @log('') if x > 0
      @log "#{v.name}                                     #{moment(v.created_at).format('YYYY-MM-DD hh:mm:ss Z')}"
      @log(chalk.yellow(line)) for line in lines
      @log chalk.gray('http://' + v.domain)

    callback()

exports.open = (box, version, callback) ->
  client = @client.keyed()
  return callback(errors.unauthorized()) unless client?
  
  if typeof version is 'function'
    callback = version
    version = box
    
    box_config = config(process.cwd() + '/.awesomebox')
    return callback(new Error('Please specify a box name')) unless box_config.get('id')?
    box = box_config.get('id')
  
  client.box(box).version(version).get (err, version) =>
    return callback(err) if err?
    
    url = 'http://' + version.domain
    @log "Opening #{url}"
    require('open')(url)
    
    callback()
