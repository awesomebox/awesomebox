exports.extension = 'json'

exports.process = (parser, text) ->
  JSON.parse(text)
