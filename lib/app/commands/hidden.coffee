q = require 'q'
path = require 'path'
config = require '../config'
{chalk} = require 'commandment'

lpad = (v, size, c = ' ') -> new Array((size - v.toString().length) + 1).join(c.toString()) + v

format_datetime = (date) ->
  d = [date.getFullYear(), lpad(date.getMonth() + 1, 2, 0), lpad(date.getDate(), 2, 0)].join('-')
  t = [lpad(date.getHours(), 2, 0), lpad(date.getMinutes(), 2, 0), lpad(date.getSeconds(), 2, 0)].join(':')
  z = date.getTimezoneOffset()
  z = (if z < 0 then '+' else '-') + ((100 * parseInt(z / 60)) + (z % 60))
  
  "#{d} #{t} #{z}"

exports.boxes = ->
  client = @client.keyed()
  throw errors.unauthorized() unless client?
  
  client.boxes.list()
  .then (boxes) =>
    @log(JSON.stringify(boxes, null, 2))

exports.versions = (box) ->
  client = @client.keyed()
  throw errors.unauthorized() unless client?
  
  unless box?
    box_config = config(path.join(process.cwd(), '.awesomebox'))
    throw new Error('Please specify a box name') unless box_config.get('id')?
    box = box_config.get('id')
  
  client.box(box).versions.list()
  .then (versions) =>
    versions = versions.sort (lhs, rhs) -> lhs.number > rhs.number
    
    for x in [0...versions.length]
      v = versions[x]
      
      msg = v.message
      lines = [msg.slice(0, 60)]
      lines.push(msg.slice(0, 60)) while (msg = msg.slice(60)) isnt ''
      
      @log('') if x > 0
      @log "#{v.name}                                     #{format_datetime(new Date(v.created_at))}"
      @log(chalk.yellow(line)) for line in lines
      @log chalk.gray('http://' + v.domain)

exports.open = (box, version) ->
  client = @client.keyed()
  throw errors.unauthorized() unless client?
  
  unless version?
    version = box
    
    box_config = config(path.join(process.cwd(), '.awesomebox'))
    throw new Error('Please specify a box name') unless box_config.get('id')?
    box = box_config.get('id')
  
  client.box(box).version(version).get()
  .then (version) =>
    url = 'http://' + version.domain
    @log "Opening #{url}"
    require('open')(url)
