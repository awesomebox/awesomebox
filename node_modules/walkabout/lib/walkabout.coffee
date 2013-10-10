fs = require 'fs'
util = require 'util'
mkdirp = require 'mkdirp'
PATH = require 'path'

_ = require 'underscore'
rimraf = require 'rimraf'

class walkabout
  constructor: (path = process.cwd()) ->
    @path = PATH.normalize(path.toString())
    @absolute_path = PATH.resolve(@path)
    # [x, x, @basename, @extension] = /^(.*\/)?(?:$|(.+?)(?:(\.[^.]*$)|$))/.exec(@path)
    # @filename = (@basename or '') + (@extension or '')
    # @extension = @extension.slice(1) if @extension?
    
    @dirname = PATH.dirname(@path)
    @extension = PATH.extname(@path)
    @filename = PATH.basename(@path)
    @basename = PATH.basename(@path, @extension)
    @extension = @extension.replace(/^\.+/, '')
    
  @is_walkabout: (candidate) ->
    candidate.path? and candidate.dirname? and candidate.filename? and candidate.basename?
    
  join: (subpaths...) ->
    subpaths = subpaths.map (p) -> if walkabout.is_walkabout(p) then p.path else p
    new walkabout(PATH.join @path, subpaths...)
  
  toString: ->
    @path

  require: ->
    require(@absolute_path)

  # PATH METHODS
  exists: (callback) ->
    (fs.exists or PATH.exists)(@absolute_path, callback)

  exists_sync: ->
    (fs.existsSync or PATH.existsSync)(@absolute_path)

  # FS METHODS
  create_read_stream: ->
    fs.createReadStream(@absolute_path)
  
  create_write_stream: ->
    fs.createWriteStream(@absolute_path)
  
  link: (dest, callback) ->
    fs.link(@absolute_path, (if walkabout.is_walkabout(dest) then dest.path else dest), callback)
  
  link_sync: (dest) ->
    fs.linkSync(@absolute_path, (if walkabout.is_walkabout(dest) then dest.path else dest))
  
  symlink: (dest, type, callback) ->
    if typeof type is 'function'
      callback = type
      type = 'file'
    fs.symlink(@absolute_path, (if walkabout.is_walkabout(dest) then dest.path else dest), type, callback)

  symlink_sync: (dest, type = 'file') ->
    fs.symlinkSync(@absolute_path, (if walkabout.is_walkabout(dest) then dest.path else dest), type)
  
  mkdir: (mode, callback) ->
    if typeof mode is 'function'
      callback = mode
      mode = 0o777
    fs.mkdir(@absolute_path, mode, callback)
  
  mkdir_sync: (mode = 0o777) ->
    fs.mkdirSync(@absolute_path, mode)
  
  mkdirp: (mode, callback) ->
    if typeof mode is 'function'
      callback = mode
      mode = 0o777
    mkdirp.sync(@absolute_path, mode, callback)
  
  mkdirp_sync: (mode = 0o777) ->
    mkdirp.sync(@absolute_path, mode)

  readdir: (callback) ->
    fs.readdir @absolute_path, (err, files) =>
      return callback(err) if err?
      callback(err, files.map (f) => @join(f))

  readdir_sync: ->
    fs.readdirSync(@absolute_path).map (f) => @join(f)
  
  readlink: (callback) ->
    fs.readlink(@absolute_path, callback)
  
  readlink_sync: ->
    fs.readlinkSync(@absolute_path)
  
  realpath: (cache, callback) ->
    if typeof cache is 'function'
      callback = cache
      cache = undefined
    fs.realpath(@absolute_path, cache, callback)
  
  realpath_sync: (cache = undefined) ->
    fs.realpathSync(@absolute_path, cache)
  
  read_file: (encoding, callback) ->
    if typeof encoding is 'function'
      callback = encoding
      encoding = 'utf8'
    fs.readFile(@absolute_path, encoding, callback)

  read_file_sync: (encoding = 'utf8') ->
    fs.readFileSync(@absolute_path, encoding)
  
  stat: (callback) ->
    fs.stat(@absolute_path, callback)
  
  stat_sync: ->
    fs.statSync(@absolute_path)
  
  write_file: (data, encoding, callback) ->
    if typeof encoding is 'function'
      callback = encoding
      encoding = 'utf8'
    fs.writeFile(@absolute_path, data, encoding, callback)
    
  write_file_sync: (data, encoding = 'utf8') ->
    fs.writeFileSync(@absolute_path, data, encoding)
  
  unlink: (callback) ->
    fs.unlink(@absolute_path, callback)
  
  unlink_sync: ->
    fs.unlinkSync(@absolute_path)
  
  rm_rf: (callback) ->
    rimraf(@absolute_path, callback)
  
  rm_rf_sync: ->
    rimraf.sync(@absolute_path)

  # HELPER METHODS
  is_directory_empty: (callback) ->
    @readdir (err, files) ->
      return callback(err) if err? and 'ENOENT' isnt err.code
      callback(null, files.length is 0)
  
  is_directory_empty_sync: ->
    try
      return @readdir_sync().length is 0
    catch e
      throw e if e? and 'ENOENT' isnt e.code
    false
  
  copy: (to, callback) ->
    src = @
    src.exists (err, exists) ->
      return callback(err) if err?
      return callback(new Error("File #{src} does not exist.")) unless exists
    
      dest = if walkabout.is_walkabout(to) then to else new walkabout(to)
      dest.exists (err, exists) ->
        return callback(err) if err?
        return callback(new Error("File #{to} already exists.")) if exists
        
        input = src.create_read_stream()
        output = dest.create_write_stream()
        util.pump(input, output, callback)
  
  copy_sync: (to) ->
    throw new Error("File #{@} does not exist.") unless @exists_sync()
    dest = if walkabout.is_walkabout(to) then to else new walkabout(to)
    throw new Error("File #{to} already exists.") if dest.exists_sync()

    dest.write_file_sync(@read_file_sync())
  
  is_directory: (callback) ->
    @stat (err, stats) ->
      callback(err, if stats? then stats.isDirectory() else null)
  
  is_directory_sync: ->
    @stat_sync().isDirectory()
  
  is_absolute: ->
    @path[0] is '/'
  
  # ls: (opts, callback) ->
  #   if typeof opts is 'function'
  #     callback = opts
  #     opts = {}
  #   
  #   opts.filter ?= -> true
  #   if opts.extensions
  #     ext = _(opts.extensions).inject ((o, e) -> o[e] = 1; o), {}
  #     _filter = opts.filter
  #     opts.filter = (p) ->
  #       return false unless ext[p.extension]?
  #       _filter(p)
  #     delete opts.extensions
  #   
  #   @readdir (err, files) ->
  #     return callback(err) if err?
  #     
  #     if opts.recursive
  #       dirs = files.filter (f) -> f.is_directory_sync()
  #         
  #       _.chain(files).
  #       
  #     files = files.filter(opts.filter)
  #     callback(null, files)
  
  ls_sync: (opts = {}) ->
    opts.filter ?= -> true
    if opts.extensions
      ext = _(opts.extensions).inject ((o, e) -> o[e] = 1; o), {}
      _filter = opts.filter
      opts.filter = (p) ->
        return false unless ext[p.extension]?
        _filter(p)
      delete opts.extensions
    
    files = @readdir_sync()
    
    if opts.recursive
      sub_files = _.chain(files).collect (f) ->
        try
          f.ls_sync(opts) if f.is_directory_sync()
        catch err
          # nerf
      .flatten()
      .compact()
      .value()
      Array::push.apply(files, sub_files)
    
    files.filter(opts.filter)
  
  directory: ->
    new walkabout(@dirname)

module.exports = (path) ->
  new walkabout(path)

module.exports.walkabout = walkabout
