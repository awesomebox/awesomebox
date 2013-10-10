_ = require 'underscore'
json = require 'json3'
walkabout = require 'walkabout'

class Config
  constructor: (path) ->
    @path = walkabout(path)
    @_load()
  
  _load: ->
    if @path.exists_sync()
      try
        @properties = json.parse(@path.read_file_sync())
      catch err
        @properties = {}
    @properties ?= {}
  
  _save: ->
    @path.write_file_sync(json.stringify(@properties, null, 2))
  
  _get_value: (k) ->
    c = @properties
    for p in k.split('.')
      return null unless c?
      c = c[p]
    c
  
  _set_value: (k, v) ->
    c = @properties
    parts = k.split('.')
    for p in parts[0...-1]
      c[p] ?= {}
      c = c[p]
    c[parts[parts.length - 1]] = v
  
  _unset_value: (k) ->
    c = @properties
    parts = k.split('.')
    for p in parts[0...-1]
      return unless c?
      c = c[p]
    delete c[parts[parts.length - 1]]
  
  get: (keys...) ->
    return @_get_value(keys[0]) if keys.length is 1
    
    data = {}
    for k in keys
      v = @_get_value(k)
      data[k] = v if v?
    data
    
  set: (k, v) ->
    if v? and typeof k is 'string'
      (obj = {})[k] = v
    else
      obj = k
    
    _(@properties).extend(obj)
    @_save()
    @
  
  unset: (keys...) ->
    @_unset_value(k) for k in keys
    @_save()
    @

module.exports = (path) -> new Config(path)
