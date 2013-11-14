q = require 'q'
fs = require 'fs'
path = require 'path'
syncr = require 'syncr'

class Synchronizer
  constructor: (@client) ->
    
  sync: (sync_opts) ->
    sync_opts.root = path.resolve(sync_opts.root)
    opts = {}
    ignore = path.join(sync_opts.root, '.awesomeboxignore')
    if fs.existsSync(ignore)
      opts.ignore_file = ignore
    else
      opts.ignore = ['node_modules', 'bin']
    
    box = @client.box(sync_opts.box)
    manifest = null
    delta = null
    sync_opts.metadata = {done: true}
    
    q.nfcall(syncr.create_manifest, sync_opts.root, opts)
    .then (manifest_) ->
      manifest = manifest_
      box.push(manifest: manifest)
    .then (delta_) ->
      delta = delta_
      return if delta is true
      
      sync_opts.metadata.branch = delta.branch
      q.ninvoke(sync_opts, 'collect_metadata')
      .then (meta) ->
        sync_opts.metadata[k] = v for k, v of meta
        
        files_to_send = delta.add.concat(delta.change)
        files_to_send.reduce (promise, file) ->
          sync_opts.on_progress("Sending #{file}...")
          file_path = path.join(sync_opts.root, file)
          
          q.ninvoke(box, 'push', path: file, hash: manifest.files[file], branch: delta.branch, file: fs.createReadStream(file_path))
          .then ->
            sync_opts.on_progress("Sending #{file}... Done")
          .catch (err) ->
            sync_opts.on_progress("Sending #{file}... Error: #{err.message}")
            throw err
        , q()
    .then ->
      q.ninvoke(box, 'push', sync_opts.metadata)

module.exports = Synchronizer
