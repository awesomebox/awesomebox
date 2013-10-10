fs = require 'fs'
stream = require 'stream'
Rest = require 'rest.node'

encode = (v) -> encodeURIComponent(v).replace('.', '%2E')

Api = {
  Users: class UsersApi
    constructor: (@client) ->
    reserve: (data, cb) -> @client.post('/users/reserve', data, cb)
    redeem: (data, cb) -> @client.post('/users/redeem', data, cb)
  
  Me: class MeApi
    constructor: (@client) ->
    get: (cb) -> @client.get('/me', cb)
  
  Boxes: class BoxesApi
    constructor: (@client) ->
    list: (cb) -> @client.get('/boxes', cb)
    create: (data, cb) -> @client.post('/boxes', data, cb)
  
  Box: class BoxApi
    constructor: (@client, @box) ->
      @versions = new Api.Versions(@client, @box)
    get: (cb) -> @client.get("/boxes/#{@box}", cb)
    push: (data, cb) -> @client.put("/boxes/#{@box}", data, cb)
    version: (version) -> new Api.Version(@client, @box, version)
  
  Versions: class VersionsApi
    constructor: (@client, @box) ->
    list: (opts, cb) -> @client.get("/boxes/#{@box}/versions", opts, cb)
  
  Version: class VersionApi
    constructor: (@client, @box, @version) ->
    get: (cb) -> @client.get("/boxes/#{@box}/versions/#{@version}", cb)
  
  Providers: class ProvidersApi
    constructor: (@client) ->
    list: (cb) -> @client.get('/providers', cb)
    create: (opts, cb) -> @client.post('/providers', opts, cb)
  
  Provider: class ProviderApi
    constructor: (@client, @provider) ->
    get: (cb) -> @client.get("/providers/#{@provider}", cb)
    update: (opts, cb) -> @client.put("/providers/#{@provider}", opts, cb)
    destroy: (cb) -> @client.delete("/providers/#{@provider}", cb)
  
  # Apps: class AppsApi
  #   constructor: (@client) ->
  #   list: (cb) -> @client.get('/apps', cb)
  #   create: (name, cb) -> @client.post('/apps', {name: name}, cb)
  # 
  # App: class AppApi
  #   constructor: (@client, @app) ->
  #     @domains = new Api.Domains(@client, @app)
  #     @versions = new Api.Versions(@client, @app)
  #   
  #   get: (cb) -> @client.get("/apps/#{encode(@app)}", cb)
  #   # status: (cb) -> @client.get("/apps/#{encode(@app)}/status", cb)
  #   # stop: (cb) -> @client.get("/apps/#{encode(@app)}/stop", cb)
  #   # start: (cb) -> @client.get("/apps/#{encode(@app)}/start", cb)
  #   # logs: (cb) -> @client.get("/apps/#{encode(@app)}/logs", cb)
  #   update: (file, data, cb) ->
  #     file = fs.createReadStream(file) if typeof file is 'string'
  #     return callback(new Error('File must be a string or a readable stream')) unless file instanceof require('stream')
  #     if typeof data is 'function'
  #       cb = data
  #       data = {}
  #     
  #     req = @client.put("/apps/#{encode(@app)}", cb)
  #     form = req.form()
  #     form.append('file', file)
  #     form.append(k, v) for k, v of data
  #     req.on('error', cb)
  #   version: (version) -> new Api.Version(@client, @app, version)
  # 
  # Domains: class DomainsApi
  #   constructor: (@client, @app) ->
  #   list: (cb) -> @client.get("/apps/#{encode(@app)}/domains", cb)
  #   add: (domain, cb) -> @client.post("/apps/#{encode(@app)}/domains", {domain: domain}, cb)
  #   remove: (domain, cb) -> @client.delete("/apps/#{encode(@app)}/domains/#{encode(domain)}", cb)
  # 
  # Versions: class VersionsApi
  #   constructor: (@client, @app) ->
  #   list: (cb) -> @client.get("/apps/#{encode(@app)}/versions", cb)
  #   remove: (version, cb) -> @client.delete("/apps/#{encode(@app)}/versions/#{encode(version)}", cb)
  # 
  # Version: class VersionApi
  #   constructor: (@client, @app, @version) ->
  #   start: (cb) -> @client.post("/apps/#{encode(@app)}/versions/#{encode(@version)}/start", cb)
  #   stop: (cb) -> @client.post("/apps/#{encode(@app)}/versions/#{encode(@version)}/stop", cb)
  #   status: (cb) -> @client.get("/apps/#{encode(@app)}/versions/#{encode(@version)}/status", cb)
  #   bless: (cb) -> @client.post("/apps/#{encode(@app)}/versions/#{encode(@version)}/bless", cb)
  #   logs: (cb) -> @client.get("/apps/#{encode(@app)}/versions/#{encode(@version)}/logs", cb)
}

class Awesomebox extends Rest
  @hooks:
    json: (request_opts, opts) ->
      request_opts.headers ?= {}
      request_opts.headers.Accept = 'application/json'
    
    api_key: (api_key) ->
      (request_opts, opts) ->
        request_opts.headers ?= {}
        request_opts.headers['x-awesomebox-key'] = api_key
    
    email_password: (email, password) ->
      (request_opts, opts) ->
        request_opts.auth =
          user: email
          pass: password
    
    data_to_querystring: (request_opts, opts) ->
      request_opts.qs = opts
    
    data_to_form: (request_opts, opts) ->
      return if opts.__attach_files__ is true
      request_opts.form = opts
    
    attach_files: (request_opts, opts, req) ->
      return unless opts.__attach_files__ is true
      delete opts.__attach_files__
      
      form = req.form()
      form.append(k, v) for k, v of opts
      req.on 'error', (err) -> req.emit('error', err)
      
    pre_attach_files: (request_opts, opts) ->
      ReadableStream = stream.Readable or stream.Stream
      
      for k, v of opts
        if v instanceof ReadableStream
          opts.__attach_files__ = true
          return
    
  constructor: (@options = {}) ->
    super(base_url: @options.base_url or 'http://api.awesomebox.es')
    
    @hook('pre:request', Awesomebox.hooks.json)
    @hook('pre:request', Awesomebox.hooks.api_key(@options.api_key)) if @options.api_key?
    @hook('pre:request', Awesomebox.hooks.email_password(@options.email, @options.password)) if @options.email? and @options.password?
    
    @hook('pre:get', Awesomebox.hooks.data_to_querystring)
    
    @hook('pre:post', Awesomebox.hooks.pre_attach_files)
    @hook('pre:post', Awesomebox.hooks.data_to_form)
    @hook('post:post', Awesomebox.hooks.attach_files)
    
    @hook('pre:put', Awesomebox.hooks.pre_attach_files)
    @hook('pre:put', Awesomebox.hooks.data_to_form)
    @hook('post:put', Awesomebox.hooks.attach_files)
    
    @users = new Api.Users(@)
    @me = new Api.Me(@)
    @boxes = new Api.Boxes(@)
    @providers = new Api.Providers(@)
  
  box: (box) -> new Api.Box(@, box)
  provider: (provider) -> new Api.Provider(@, provider)

module.exports = Awesomebox
