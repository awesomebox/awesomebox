exports.dependencies = 'react-tools'
exports.extension = 'jsx'
exports.attr_types =
  'text/jsx': 'jsx'

remove_comments = (v) ->
  while (idx = v.indexOf('/*')) isnt -1
    v = v.slice(v.indexOf('*/', idx) + 2)
  v

exports.process = (opts, callback) ->
  opts.text = '/** @jsx React.DOM */\n' + remove_comments(opts.text)
  
  process.nextTick ->
    try
      callback(null, opts.dependencies['react-tools'].transform(opts.text))
    catch err
      callback(err)
