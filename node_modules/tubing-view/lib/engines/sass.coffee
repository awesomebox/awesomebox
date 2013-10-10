exports.dependencies = 'sass'
exports.extensions = ['sass', 'scss']
exports.attr_types =
  'text/sass': 'sass'
  'text/scss': 'scss'

exports.process = (opts, callback) ->
  process.nextTick ->
    try
      callback(null, opts.dependencies.sass.render(opts.text))
    catch err
      callback(err)
