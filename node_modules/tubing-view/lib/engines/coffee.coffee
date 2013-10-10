exports.dependencies = 'coffee-script'
exports.extension = 'coffee'
exports.attr_types =
  'text/coffeescript': 'coffee'

exports.process = (opts, callback) ->
  process.nextTick ->
    try
      callback(null, opts.dependencies['coffee-script'].compile(opts.text, bare: true))
    catch err
      callback(err)
