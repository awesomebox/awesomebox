exports.dependencies = ['marked', 'pygmentize-bundled']
exports.extensions = ['markdown', 'md']

exports.process = (opts, callback) ->
  marked = opts.dependencies.marked
  pygmentize = opts.dependencies['pygmentize-bundled']
  
  marked.setOptions(
    highlight: (code, lang, callback) ->
      pygmentize lang: lang, format: 'html', code, (err, result) ->
        return callback(err) if err?
        callback(null, result.toString())
  )
  
  process.nextTick ->
    try
      callback(null, marked(opts.text))
    catch err
      callback(err)
