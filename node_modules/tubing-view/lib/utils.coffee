String::startsWith = (str) ->
  return false if @length < str.length
  
  for x in [0...str.length]
    return false unless @[x] is str[x]
  true

find_file = (needle, haystack) ->
  for file in haystack
    return file if file.filename.startsWith(needle) and (file.filename.length is needle.length or file.filename[needle.length] is '.')
  null

is_path_in_root = (root, path) ->
  require('path').relative(root.absolute_path, path).indexOf('..') is -1

exports.resolve_path_from_root = (root, paths, callback) ->
  paths = [paths] unless Array.isArray(paths)
  
  step = (idx) ->
    return callback() if idx is paths.length
    
    path = paths[idx]
    p = root.join(path)
    p.directory().readdir (err, files) ->
      if files?
        f = find_file(p.filename, files)
        return callback(null, f, path) if f? and is_path_in_root(root, f.absolute_path)
      step(idx + 1)
  
  step(0)

exports.resolve_path_from_root_sync = (root, paths) ->
  paths = [paths] unless Array.isArray(paths)
  
  for path in paths
    p = root.join(path)
    try
      f = find_file(p.filename, p.directory().readdir_sync())
      return f if f? and is_path_in_root(root, f.absolute_path)
    catch err
  
  null
