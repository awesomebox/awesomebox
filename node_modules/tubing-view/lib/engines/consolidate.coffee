exports.dependencies = (engine) -> ['consolidate', engine]

# https://npmjs.org/package/consolidate
exports.extensions = [
  'atpl'
  'dust'
  'eco'
  'ect'
  'ejs'
  'haml'
  'haml-coffee'
  'handlebars'
  'jade'
  'jazz'
  'jqtpl'
  'just'
  'liquor'
  'mustache'
  'qejs'
  'swig'
  'templayed'
  'toffee'
  'underscore'
  'walrus'
  'whiskers'
]

exports.process = (opts, callback) ->
  opts.dependencies.consolidate[opts.engine].render(opts.text, opts.data, callback)
