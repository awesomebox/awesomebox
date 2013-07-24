exports.dependencies = 'js-yaml'
exports.extensions = ['yml', 'yaml']

exports.process = (parser, text) ->
  require('js-yaml').load(text)
