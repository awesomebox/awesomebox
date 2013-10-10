(function() {
  var Engines, betturl, mime, tubing, utils, walkabout;

  mime = require('mime');

  tubing = require('tubing');

  betturl = require('betturl');

  walkabout = require('walkabout');

  utils = exports.utils = require('./utils');

  Engines = exports.Engines = require('./engines');

  exports.adapt_http_req = function(cmd, done) {
    var _base, _ref;
    cmd.path = cmd.req.url;
    if ((_ref = (_base = cmd.req).view) == null) {
      _base.view = {};
    }
    cmd.req.view.pipeline = this.pipeline;
    cmd.req.view.command = cmd;
    return done();
  };

  exports.resolve_content_type = function(cmd, done) {
    var content_type;
    try {
      cmd.parsed = betturl.parse(cmd.path);
      if (cmd.content_type == null) {
        content_type = mime.lookup(cmd.parsed.path);
        if (content_type === 'application/octet-stream' && (cmd.req != null)) {
          content_type = cmd.req.accepted[0].value;
        }
        cmd.content_type = mime.extension(content_type);
      }
      try {
        cmd.mime_type = mime.lookup(cmd.content_type);
      } catch (err) {
        cmd.mime_type = 'text/plain';
      }
      cmd.mime_charset = mime.charsets.lookup(cmd.mime_type);
    } catch (err) {
      return done(err);
    }
    return done();
  };

  exports.resolve_path = function(cmd, done) {
    var path, path_base, paths,
      _this = this;
    path = cmd.parsed.path.replace(new RegExp('\.' + cmd.content_type + '$'), '');
    paths = ["" + path + "." + cmd.content_type, "" + path + "/index." + cmd.content_type];
    path_base = cmd.parsed.path.slice(cmd.parsed.path.lastIndexOf('/') + 1);
    if (new RegExp("\\b" + cmd.content_type + "\\b").test(path_base)) {
      paths.push(cmd.parsed.path);
    }
    return utils.resolve_path_from_root(this.config.path[this.config.resolve_to], paths, function(err, content_path) {
      var engines;
      if (err != null) {
        console.log(err.stack);
      }
      if (err != null) {
        return done(err);
      }
      if (content_path == null) {
        return done();
      }
      cmd.resolved = {
        file: content_path,
        path: walkabout(content_path.absolute_path.slice(_this.config.path[_this.config.resolve_to].absolute_path.length))
      };
      engines = content_path.absolute_path.slice(content_path.absolute_path.lastIndexOf(path) + path.length);
      engines = engines.replace(new RegExp('^(/?index)?\.' + cmd.content_type + '\.?'), '').split('.');
      cmd.engines = engines.filter(function(e) {
        return (e != null) && e !== '';
      }).reverse();
      return done();
    });
  };

  exports.fetch_content = function(cmd, done) {
    return cmd.resolved.file.read_file(function(err, content) {
      if (err != null) {
        return done(err);
      }
      cmd.content = content.toString();
      return done();
    });
  };

  exports.create_params = function(cmd, done) {
    var k, v, _base, _ref, _ref1, _ref2;
    if ((_ref = cmd.data) == null) {
      cmd.data = {};
    }
    if ((_ref1 = (_base = cmd.data).params) == null) {
      _base.params = {};
    }
    _ref2 = cmd.parsed.query;
    for (k in _ref2) {
      v = _ref2[k];
      cmd.data.params[k] = v;
    }
    return done();
  };

  exports.render_engines = function(cmd) {
    var d, step;
    d = this.defer();
    step = function(idx) {
      if (idx === cmd.engines.length) {
        return d.resolve(cmd);
      }
      try {
        return Engines.render(cmd.engines[idx], cmd.content, cmd.data, cmd.resolved.file.absolute_path, function(err, data) {
          if (err != null) {
            return d.reject(err);
          }
          cmd.content = data;
          return step(idx + 1);
        });
      } catch (err) {
        return d.reject(err);
      }
    };
    step(0);
    return d.promise;
  };

  exports.ViewPipeline = tubing.pipeline('View Pipeline').then(exports.resolve_content_type).then(exports.resolve_path).then(tubing.exit_unless('resolved')).then(exports.fetch_content).then(exports.create_params).then(exports.render_engines).configure(function(pipeline, config) {
    var k, _i, _len, _ref, _results;
    _ref = config.path;
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      k = _ref[_i];
      _results.push(config.path[k] = walkabout(config.path[k]));
    }
    return _results;
  });

  exports.HttpViewPipeline = tubing.pipeline('Http View Pipeline').then(exports.adapt_http_req).then(exports.ViewPipeline);

}).call(this);
