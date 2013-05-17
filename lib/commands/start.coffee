exports.args = 'version'

exports.execute = (context, version, callback) ->
  context.client().app(awesomebox.name).start(version, callback)
