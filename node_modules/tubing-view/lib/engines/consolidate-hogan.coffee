exports.dependencies = ['consolidate', 'hogan.js']

# https://npmjs.org/package/consolidate
exports.extension = 'hogan'

exports.process = (opts, callback) ->
  opts.dependencies.consolidate.hogan.render(opts.text, opts.data, callback)
