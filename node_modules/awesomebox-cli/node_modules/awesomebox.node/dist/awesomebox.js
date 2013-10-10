(function() {
  var Api, Awesomebox, BoxApi, BoxesApi, MeApi, ProviderApi, ProvidersApi, Rest, UsersApi, VersionApi, VersionsApi, encode, fs, stream,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  fs = require('fs');

  stream = require('stream');

  Rest = require('rest.node');

  encode = function(v) {
    return encodeURIComponent(v).replace('.', '%2E');
  };

  Api = {
    Users: UsersApi = (function() {

      function UsersApi(client) {
        this.client = client;
      }

      UsersApi.prototype.reserve = function(data, cb) {
        return this.client.post('/users/reserve', data, cb);
      };

      UsersApi.prototype.redeem = function(data, cb) {
        return this.client.post('/users/redeem', data, cb);
      };

      return UsersApi;

    })(),
    Me: MeApi = (function() {

      function MeApi(client) {
        this.client = client;
      }

      MeApi.prototype.get = function(cb) {
        return this.client.get('/me', cb);
      };

      return MeApi;

    })(),
    Boxes: BoxesApi = (function() {

      function BoxesApi(client) {
        this.client = client;
      }

      BoxesApi.prototype.list = function(cb) {
        return this.client.get('/boxes', cb);
      };

      BoxesApi.prototype.create = function(data, cb) {
        return this.client.post('/boxes', data, cb);
      };

      return BoxesApi;

    })(),
    Box: BoxApi = (function() {

      function BoxApi(client, box) {
        this.client = client;
        this.box = box;
        this.versions = new Api.Versions(this.client, this.box);
      }

      BoxApi.prototype.get = function(cb) {
        return this.client.get("/boxes/" + this.box, cb);
      };

      BoxApi.prototype.push = function(data, cb) {
        return this.client.put("/boxes/" + this.box, data, cb);
      };

      BoxApi.prototype.version = function(version) {
        return new Api.Version(this.client, this.box, version);
      };

      return BoxApi;

    })(),
    Versions: VersionsApi = (function() {

      function VersionsApi(client, box) {
        this.client = client;
        this.box = box;
      }

      VersionsApi.prototype.list = function(opts, cb) {
        return this.client.get("/boxes/" + this.box + "/versions", opts, cb);
      };

      return VersionsApi;

    })(),
    Version: VersionApi = (function() {

      function VersionApi(client, box, version) {
        this.client = client;
        this.box = box;
        this.version = version;
      }

      VersionApi.prototype.get = function(cb) {
        return this.client.get("/boxes/" + this.box + "/versions/" + this.version, cb);
      };

      return VersionApi;

    })(),
    Providers: ProvidersApi = (function() {

      function ProvidersApi(client) {
        this.client = client;
      }

      ProvidersApi.prototype.list = function(cb) {
        return this.client.get('/providers', cb);
      };

      ProvidersApi.prototype.create = function(opts, cb) {
        return this.client.post('/providers', opts, cb);
      };

      return ProvidersApi;

    })(),
    Provider: ProviderApi = (function() {

      function ProviderApi(client, provider) {
        this.client = client;
        this.provider = provider;
      }

      ProviderApi.prototype.get = function(cb) {
        return this.client.get("/providers/" + this.provider, cb);
      };

      ProviderApi.prototype.update = function(opts, cb) {
        return this.client.put("/providers/" + this.provider, opts, cb);
      };

      ProviderApi.prototype.destroy = function(cb) {
        return this.client["delete"]("/providers/" + this.provider, cb);
      };

      return ProviderApi;

    })()
  };

  Awesomebox = (function(_super) {

    __extends(Awesomebox, _super);

    Awesomebox.hooks = {
      json: function(request_opts, opts) {
        var _ref;
        if ((_ref = request_opts.headers) == null) {
          request_opts.headers = {};
        }
        return request_opts.headers.Accept = 'application/json';
      },
      api_key: function(api_key) {
        return function(request_opts, opts) {
          var _ref;
          if ((_ref = request_opts.headers) == null) {
            request_opts.headers = {};
          }
          return request_opts.headers['x-awesomebox-key'] = api_key;
        };
      },
      email_password: function(email, password) {
        return function(request_opts, opts) {
          return request_opts.auth = {
            user: email,
            pass: password
          };
        };
      },
      data_to_querystring: function(request_opts, opts) {
        return request_opts.qs = opts;
      },
      data_to_form: function(request_opts, opts) {
        if (opts.__attach_files__ === true) {
          return;
        }
        return request_opts.form = opts;
      },
      attach_files: function(request_opts, opts, req) {
        var form, k, v;
        if (opts.__attach_files__ !== true) {
          return;
        }
        delete opts.__attach_files__;
        form = req.form();
        for (k in opts) {
          v = opts[k];
          form.append(k, v);
        }
        return req.on('error', function(err) {
          return req.emit('error', err);
        });
      },
      pre_attach_files: function(request_opts, opts) {
        var ReadableStream, k, v;
        ReadableStream = stream.Readable || stream.Stream;
        for (k in opts) {
          v = opts[k];
          if (v instanceof ReadableStream) {
            opts.__attach_files__ = true;
            return;
          }
        }
      }
    };

    function Awesomebox(options) {
      this.options = options != null ? options : {};
      Awesomebox.__super__.constructor.call(this, {
        base_url: this.options.base_url || 'http://api.awesomebox.es'
      });
      this.hook('pre:request', Awesomebox.hooks.json);
      if (this.options.api_key != null) {
        this.hook('pre:request', Awesomebox.hooks.api_key(this.options.api_key));
      }
      if ((this.options.email != null) && (this.options.password != null)) {
        this.hook('pre:request', Awesomebox.hooks.email_password(this.options.email, this.options.password));
      }
      this.hook('pre:get', Awesomebox.hooks.data_to_querystring);
      this.hook('pre:post', Awesomebox.hooks.pre_attach_files);
      this.hook('pre:post', Awesomebox.hooks.data_to_form);
      this.hook('post:post', Awesomebox.hooks.attach_files);
      this.hook('pre:put', Awesomebox.hooks.pre_attach_files);
      this.hook('pre:put', Awesomebox.hooks.data_to_form);
      this.hook('post:put', Awesomebox.hooks.attach_files);
      this.users = new Api.Users(this);
      this.me = new Api.Me(this);
      this.boxes = new Api.Boxes(this);
      this.providers = new Api.Providers(this);
    }

    Awesomebox.prototype.box = function(box) {
      return new Api.Box(this, box);
    };

    Awesomebox.prototype.provider = function(provider) {
      return new Api.Provider(this, provider);
    };

    return Awesomebox;

  })(Rest);

  module.exports = Awesomebox;

}).call(this);
