exports.dependencies = 'recess'
exports.extension = 'less'
exports.attr_types =
  'text/less': 'less'

exports.process = (opts, callback) ->
  Recess = opts.dependencies.recess.Constructor
  instance = new Recess()
  instance.options.compile = true
  # instance.options.compress = true
  instance.path = opts.filename or '/path.less'
  instance.data = opts.text
  instance.callback = ->
    if instance.errors.length > 0
      return callback(new Error(instance.errors[0].message))
    callback(null, instance.output.join('\n'))

  instance.parse()
