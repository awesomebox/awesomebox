exports.dependencies = 'stylus'
exports.extension = 'styl'
exports.attr_types =
  'text/stylus': 'styl'

exports.process = (opts, callback) ->
  opts.dependencies.stylus.render(opts.text, {filename: opts.filename or '/path.styl'}, callback)
