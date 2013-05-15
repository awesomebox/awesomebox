exports.args = '...'
exports.execute = (context, args, callback) ->
  context.commandment.help(args)
  callback()
