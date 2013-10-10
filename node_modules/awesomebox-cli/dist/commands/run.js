(function() {
  var async, nopt;

  async = require('async');

  nopt = require('commandment/node_modules/nopt');

  exports.__default__ = function(cb) {
    var awesomebox, opts, server, _ref, _ref1, _ref2, _ref3,
      _this = this;
    awesomebox = this.get('awesomebox');
    opts = nopt({
      watch: Boolean,
      'hunt-port': Boolean,
      port: Number,
      open: Boolean
    }, {
      p: '--port'
    }, process.argv);
    if ((_ref = opts.watch) == null) {
      opts.watch = true;
    }
    if ((_ref1 = opts['hunt-port']) == null) {
      opts['hunt-port'] = true;
    }
    if (process.env.PORT != null) {
      if ((_ref2 = opts.port) == null) {
        opts.port = Number(process.env.PORT);
      }
    }
    if ((_ref3 = opts.open) == null) {
      opts.open = true;
    }
    server = new awesomebox.Server(opts);
    return async.series([
      function(cb) {
        return server.initialize(cb);
      }, function(cb) {
        return server.configure(cb);
      }, function(cb) {
        return server.start(cb);
      }
    ], function(err) {
      var host, port, _ref4;
      if (err != null) {
        console.log(err.stack);
        process.exit(1);
      }
      _this.log('Listening on port', server.address.port);
      if (opts.open === true) {
        host = (_ref4 = server.address.address) === '0.0.0.0' || _ref4 === '127.0.0.1' ? 'localhost' : server.address.address;
        port = server.address.port;
        return require('open')("http://" + host + ":" + port + "/");
      }
    });
  };

}).call(this);
