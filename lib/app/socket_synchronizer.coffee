q = require 'q'
fs = require 'fs'
tar = require 'tar'
zlib = require 'zlib'
path = require 'path'
syncr = require 'syncr'
fstream = require 'fstream'
{chalk} = require 'commandment'
websockalocket = require 'websockalocket'

utils = require 'commandment/dist/utils'

build_prefix = (opts) ->
  len = utils.prefix_length(opts.prefix)
  utils.rpad(chalk[opts.color](opts.prefix) + ':', len)

class SocketSynchronizer
  constructor: (@opts) ->
  
  connect: ->
    d = q.defer()
    
    @socket = websockalocket.client(
      @opts.server.replace(/^http/, 'ws')
      headers:
        authorization: 'API Key ' + Buffer(@opts.api_key).toString('base64')
    )
    
    @socket.on('connect', -> d.resolve())
    @socket.on('close', -> d.reject(new Error('Could not connect to server')))
    
    d.promise
  
  sync_files: ->
    # box: box.id
    # root: process.cwd()
    
    send_manifest = =>
      opts = {root: path.resolve(@opts.root)}
      ignore_path = path.join(opts.root, '.awesomeboxignore')
      if fs.existsSync(ignore_path)
        opts.ignore_file = ignore_path
      else
        opts.ignore = ['node_modules', 'bin']
      
      q.nfcall(syncr.create_manifest, opts.root, opts)
      .then (manifest) =>
        @socket.send('manifest', manifest)
  
    send_files = (files_to_send) =>
      @opts.log('Sending ' + files_to_send.length + ' file(s)...')
      
      accepted_files = files_to_send.reduce (o, file) ->
        parts = file.split('/')
        for x in [0..parts.length]
          o[parts.slice(0, x + 1).join('/')] = 1
        o
      , {}
      accepted_files[''] = 1 if Object.keys(accepted_files).length > 0
      
      q()
      .then =>
        d = q.defer()
        
        root_dir = @opts.root
        
        stream = new fstream.Reader(
          path: root_dir
          type: 'Directory'
          follow: true
          filter: ->
            relative_path = @path.slice(root_dir.length).replace(/^\/*/, '')
            return false unless accepted_files[relative_path]?
            true
        ).pipe(tar.Pack()).pipe(zlib.Gzip())
      
        buffers = []
        stream.on 'data', (data) ->
          buffers.push(data)
      
        stream.on 'end', (data) ->
          buffers.push(data) if data?
          d.resolve(Buffer.concat(buffers).toString('base64'))
      
        d.promise
      .then (buffer) =>
        @socket.send('files', buffer)
      .then =>
        @opts.log('')
    
    # sync logic
    @socket.send('update-box', @opts.box)
    .then ->
      send_manifest()
    .then (delta) =>
      return if delta is true
      
      @opts.log ''
      @opts.log 'Files'
      @opts.log '  Added:  ', delta.add.length
      @opts.log '  Changed:', delta.change.length
      @opts.log '  Renamed:', Object.keys(delta.rename).length
      @opts.log '  Removed:', delta.remove.length
      @opts.log ''
      
      delta.add.concat(delta.change)
    .then (files_to_send) =>
      return unless files_to_send?
      q()
      .then ->
        return if files_to_send.length is 0
        send_files(files_to_send)
      .then =>
        @socket.send('complete-update')
        # should get a version in response
  
  start: ->
    @connect()
    .then =>
      @socket.implement(
        status: (status, progress) =>
          return @opts.log status unless progress?
          
          # console.log 'progress', status, progress
          try
            done = parseInt(progress / 5)
            not_done = 20 - done
            
            prefix = build_prefix(prefix: 'save', color: 'magenta')
            line = prefix + status + ' [' + Array(done + 1).join('=') + Array(not_done + 1).join(' ') + '] ' + parseInt(progress) + '%'
            
            process.stdout.write('\x1B[0G\x1B[0K' + line)
          catch err
            console.log err.stack
        
        'prompt-for-message': =>
          @opts.log 'Leave a message to remind yourself of the changes you made.'
          @opts.log('')
          process.stdin.setRawMode(false)
          @opts.prompt
            message: {prompt: 'message'}
          .then (data) =>
            process.stdin.setRawMode(true)
            @opts.log('')
            data.message
      )
      
      process.stdin.setRawMode(true)
      @sync_files()
    .then (version) ->
      return null unless version?
      process.stdout.write('\n')
      version
    .fin =>
      process.stdin.setRawMode(false)
      # @opts.log('')

module.exports = SocketSynchronizer
