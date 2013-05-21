tar = require 'tar'
zlib = require 'zlib'
fstream = require 'fstream'
walkabout = require 'walkabout'

exports.pack = (package_dir, zip_file, callback) ->
  zip_file = walkabout(zip_file)
  
  fstream.Reader(
    type: 'Directory'
    path: walkabout(package_dir).absolute_path
    # filter: -> @basename[0] isnt '.' and @basename not in ['node_modules', 'components']
  )
  .pipe(tar.Pack(noProprietary: true))
  .pipe(zlib.Gzip())
  .pipe(fstream.Writer(zip_file.absolute_path))
  .on('error', callback)
  .on 'close', -> callback(null, zip_file.absolute_path)

exports.unpack = (zip_file, output_dir, callback) ->
  output_dir = walkabout(output_dir)
  
  fstream.Reader(walkabout(zip_file).absolute_path)
  .pipe(zlib.Gunzip())
  .pipe(tar.Extract(
    type: 'Directory'
    path: output_dir.absolute_path)
  )
  .on 'close', -> callback(null, output_dir.absolute_path)
