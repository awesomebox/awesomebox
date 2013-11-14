fs = require 'fs'
path = require 'path'
json = require 'json3'

class Config
  constructor: (file_path) ->
    @path = path.resolve(file_path)
    @_load()
  
  _load: ->
    if fs.existsSync(@path)
      try
        @properties = json.parse(fs.readFileSync(@path).toString())
      catch err
        @properties = {}
    @properties ?= {}
  
  _save: ->
    fs.writeFileSync(@path, json.stringify(@properties, null, 2))
  
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
    
    @properties[a] = b for a, b of obj
    @_save()
    @
  
  unset: (keys...) ->
    @_unset_value(k) for k in keys
    @_save()
    @
  
  destroy: ->
    try
      fs.unlinkSync(@path)
    catch err
    
    @properties ?= {}

module.exports = (path) -> new Config(path)
