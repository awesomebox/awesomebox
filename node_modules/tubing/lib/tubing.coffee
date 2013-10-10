exports.Sink = require './sink'
exports.Source = require './source'
exports.Pipe = require './pipe'
exports.Pipeline = require './pipeline'

exports.sink = exports.Sink.define.bind(null)
exports.source = exports.Source.define.bind(null)
exports.pipe = exports.Pipe.define.bind(null)
exports.pipeline = exports.Pipeline.define.bind(null)

get_value = (obj, v) ->
  for part in v.split('.')
    obj = obj[part]
    return null unless obj?
  
  obj

filter_predicate = (accessor, predicate, action) ->
  (cmd, done) ->
    v = accessor.call(@, cmd)
    try
      return action.call(@, cmd, done) if predicate(v)
    catch err
      return done(err)
    done()

ACCESSOR =
  cmd: (cmd) -> cmd
  config: -> @config

ACTION =
  exit_pipeline: -> @exit_pipeline()

negate = (predicate) ->
  (v) ->
    !predicate(v)

is_true = (predicate) ->
  (v) ->
    predicate(v) is true

is_false = (predicate) ->
  (v) ->
    predicate(v) is false

create_filter_predicate = (value) ->
  return value if typeof value is 'function'
  
  if typeof value is 'string'
    parts = value.split(/\s+/).filter (a) -> a? and a isnt ''
    if parts.length is 1
      predicate = (v) -> get_value(v, parts[0])?
    else if parts.length is 2
      parts[0] = parts[0].toLowerCase()
      if parts[0] is 'not'
        predicate = (v) -> !get_value(v, parts[1])?
      else
        throw new Error('Unsupported if clause modifier: ' + parts[0])
    return predicate
  
  throw new Error('Unsupported if clause')

exports.exit_if = (value) ->
  predicate = create_filter_predicate(value)
  filter_predicate(ACCESSOR.cmd, predicate, ACTION.exit_pipeline)

exports.exit_unless = (value) ->
  predicate = create_filter_predicate(value)
  filter_predicate(ACCESSOR.cmd, negate(predicate), ACTION.exit_pipeline)

exports.exit_if_config = (value) ->
  predicate = create_filter_predicate(value)
  filter_predicate(ACCESSOR.config, predicate, ACTION.exit_pipeline)

exports.exit_unless_config = (value) ->
  predicate = create_filter_predicate(value)
  filter_predicate(ACCESSOR.config, negate(predicate), ACTION.exit_pipeline)

exports.exit_if_config_true = (value) ->
  predicate = create_filter_predicate(value)
  filter_predicate(ACCESSOR.config, is_true(predicate), ACTION.exit_pipeline)

exports.exit_unless_config_true = (value) ->
  predicate = create_filter_predicate(value)
  filter_predicate(ACCESSOR.config, negate(is_true(predicate)), ACTION.exit_pipeline)

exports.exit_if_config_false = (value) ->
  predicate = create_filter_predicate(value)
  filter_predicate(ACCESSOR.config, is_false(predicate), ACTION.exit_pipeline)

exports.exit_unless_config_false = (value) ->
  predicate = create_filter_predicate(value)
  filter_predicate(ACCESSOR.config, negate(is_false(predicate)), ACTION.exit_pipeline)
