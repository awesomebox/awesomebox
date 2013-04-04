npm = require 'npm'
path = require 'path'
async = require 'async'

npm_install = (pkg, callback) ->
  npm.load {prefix: liverequire.modules_path}, (err) ->
    return callback(err) if err?
    
    npm.commands.install [pkg], (err, data) ->
      return callback(err) if err?
      
      version = data[data.length - 1][0]
      module_path = path.join(liverequire.modules_path, version.split('@')[0])
      callback(null, require(module_path))

do_require = (pkg, callback) ->
  p = pkg
  p = path.resolve(path.join(process.cwd(), p)) if p[0] is '.'
  
  try
    callback(null, require(p))
  catch e
    console.log e.stack
    if p[0] is '/'
      e.message = 'Could not load ' + pkg + ': ' + e.message
      return callback(e)
    npm_install(pkg, callback)

liverequire = (pkg, callback) ->
  return do_require(pkg, callback) if typeof pkg is 'string'
  return async.map(pkg, do_require, callback) if Array.isArray(pkg)
  
  work = Object.keys(pkg).reduce (o, k) ->
    o[k] = (cb) -> do_require(pkg[k], cb)
    o
  , {}
  async.parallel(work, callback)

liverequire.modules_path = process.cwd() + '/node_modules'

module.exports = liverequire
