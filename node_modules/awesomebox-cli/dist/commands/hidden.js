(function() {
  var chalk, config, moment;

  chalk = require('chalk');

  moment = require('moment');

  config = require('../config');

  exports.boxes = function(callback) {
    var client,
      _this = this;
    client = this.client.keyed();
    if (client == null) {
      return callback(errors.unauthorized());
    }
    return client.boxes.list(function(err, boxes) {
      var line, _i, _len, _ref;
      if (err != null) {
        return callback(err);
      }
      _ref = JSON.stringify(boxes, null, 2).split('\n');
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        line = _ref[_i];
        _this.log(line);
      }
      return callback();
    });
  };

  exports.versions = function(box, callback) {
    var box_config, client,
      _this = this;
    client = this.client.keyed();
    if (client == null) {
      return callback(errors.unauthorized());
    }
    if (typeof box === 'function') {
      callback = box;
      box_config = config(process.cwd() + '/.awesomebox');
      if (box_config.get('id') == null) {
        return callback(new Error('Please specify a box name'));
      }
      box = box_config.get('id');
    }
    return client.box(box).versions.list(function(err, versions) {
      var line, lines, msg, v, x, _i, _j, _len, _ref;
      if (err != null) {
        return callback(err);
      }
      versions = versions.sort(function(lhs, rhs) {
        return lhs.number > rhs.number;
      });
      for (x = _i = 0, _ref = versions.length; 0 <= _ref ? _i < _ref : _i > _ref; x = 0 <= _ref ? ++_i : --_i) {
        v = versions[x];
        msg = v.message;
        lines = [msg.slice(0, 60)];
        while ((msg = msg.slice(60)) !== '') {
          lines.push(msg.slice(0, 60));
        }
        if (x > 0) {
          _this.log('');
        }
        _this.log("" + v.name + "                                     " + (moment(v.created_at).format('YYYY-MM-DD hh:mm:ss Z')));
        for (_j = 0, _len = lines.length; _j < _len; _j++) {
          line = lines[_j];
          _this.log(chalk.yellow(line));
        }
        _this.log(chalk.gray('http://' + v.domain));
      }
      return callback();
    });
  };

  exports.open = function(box, version, callback) {
    var box_config, client,
      _this = this;
    client = this.client.keyed();
    if (client == null) {
      return callback(errors.unauthorized());
    }
    if (typeof version === 'function') {
      callback = version;
      version = box;
      box_config = config(process.cwd() + '/.awesomebox');
      if (box_config.get('id') == null) {
        return callback(new Error('Please specify a box name'));
      }
      box = box_config.get('id');
    }
    return client.box(box).version(version).get(function(err, version) {
      var url;
      if (err != null) {
        return callback(err);
      }
      url = 'http://' + version.domain;
      _this.log("Opening " + url);
      require('open')(url);
      return callback();
    });
  };

}).call(this);
