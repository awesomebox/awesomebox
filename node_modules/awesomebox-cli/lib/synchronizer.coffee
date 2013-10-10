async = require 'async'
syncr = require 'syncr'
walkabout = require 'walkabout'

class Synchronizer
  constructor: (@client) ->
    
  sync: (sync_opts, callback) ->
    sync_opts.root = walkabout(sync_opts.root)
    opts = {}
    if sync_opts.root.join('.awesomeboxignore').exists_sync()
      opts.ignore_file = sync_opts.root.join('.awesomeboxignore').absolute_path
    else
      opts.ignore = ['node_modules', 'bin']
    
    box = @client.box(sync_opts.box)
    manifest = null
    delta = null
    sync_opts.metadata = {done: true}
    
    async.waterfall [
      (cb) -> syncr.create_manifest(sync_opts.root.absolute_path, opts, cb)
      
      (m, cb) =>
        manifest = m
        box.push(manifest: manifest, cb)
      
      (d, cb) =>
        delta = d
        return callback() if delta is true
        
        sync_opts.metadata.branch = delta.branch
        
        sync_opts.collect_metadata (err, meta) =>
          return cb(err) if err?
          sync_opts.metadata[k] = v for k, v of meta
          
          files_to_send = delta.add.concat(delta.change)
          async.eachSeries files_to_send, (path, send_cb) =>
            sync_opts.on_progress("Sending #{path}...")
            file_path = sync_opts.root.join(path)
          
            box.push {path: path, hash: manifest.files[path], branch: delta.branch, file: file_path.create_read_stream()}, (err) =>
              if err?
                sync_opts.on_progress("Sending #{path}... Error: #{err.message}")
                return send_cb(err)
              sync_opts.on_progress("Sending #{path}... Done")
              send_cb()
          , cb
    ], (err) =>
      return callback(err) if err?
      box.push(sync_opts.metadata, callback)

module.exports = Synchronizer
