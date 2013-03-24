npm = require 'npm'
path = require 'path'
async = require 'async'

npm_install = (module, callback) ->
  npm.load {prefix: liverequire.modules_path}, (err) ->
    return callback(err) if err?
    
    npm.commands.install [module], (err, data) ->
      return callback(err) if err?
      
      version = data[data.length - 1][0]
      module_path = path.join(liverequire.modules_path, version.split('@')[0])
      callback(null, require(module_path))

do_require = (module, callback) ->
  m = module
  m = path.resolve(path.join(process.cwd(), m)) unless m.indexOf('/') is -1 or m[0] is '/'
  
  try
    callback(null, require(m))
  catch e
    if m[0] is '/'
      e.message = 'Could not load ' + module + ': ' + e.message
      return callback(e)
    npm_install(module, callback)

liverequire = (module, callback) ->
  return do_require(module, callback) if typeof module is 'string'
  return async.map(module, do_require, callback) if Array.isArray(module)
  
  work = Object.keys(module).reduce (o, k) ->
    o[k] = (cb) -> do_require(module[k], cb)
    o
  , {}
  async.parallel(work, callback)

liverequire.modules_path = process.cwd() + '/node_modules'

module.exports = liverequire
