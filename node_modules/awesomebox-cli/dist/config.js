(function() {
  var Config, json, walkabout, _,
    __slice = [].slice;

  _ = require('underscore');

  json = require('json3');

  walkabout = require('walkabout');

  Config = (function() {

    function Config(path) {
      this.path = walkabout(path);
      this._load();
    }

    Config.prototype._load = function() {
      var _ref;
      if (this.path.exists_sync()) {
        try {
          this.properties = json.parse(this.path.read_file_sync());
        } catch (err) {
          this.properties = {};
        }
      }
      return (_ref = this.properties) != null ? _ref : this.properties = {};
    };

    Config.prototype._save = function() {
      return this.path.write_file_sync(json.stringify(this.properties, null, 2));
    };

    Config.prototype._get_value = function(k) {
      var c, p, _i, _len, _ref;
      c = this.properties;
      _ref = k.split('.');
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        p = _ref[_i];
        if (c == null) {
          return null;
        }
        c = c[p];
      }
      return c;
    };

    Config.prototype._set_value = function(k, v) {
      var c, p, parts, _i, _len, _ref, _ref1;
      c = this.properties;
      parts = k.split('.');
      _ref = parts.slice(0, -1);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        p = _ref[_i];
        if ((_ref1 = c[p]) == null) {
          c[p] = {};
        }
        c = c[p];
      }
      return c[parts[parts.length - 1]] = v;
    };

    Config.prototype._unset_value = function(k) {
      var c, p, parts, _i, _len, _ref;
      c = this.properties;
      parts = k.split('.');
      _ref = parts.slice(0, -1);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        p = _ref[_i];
        if (c == null) {
          return;
        }
        c = c[p];
      }
      return delete c[parts[parts.length - 1]];
    };

    Config.prototype.get = function() {
      var data, k, keys, v, _i, _len;
      keys = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      if (keys.length === 1) {
        return this._get_value(keys[0]);
      }
      data = {};
      for (_i = 0, _len = keys.length; _i < _len; _i++) {
        k = keys[_i];
        v = this._get_value(k);
        if (v != null) {
          data[k] = v;
        }
      }
      return data;
    };

    Config.prototype.set = function(k, v) {
      var obj;
      if ((v != null) && typeof k === 'string') {
        (obj = {})[k] = v;
      } else {
        obj = k;
      }
      _(this.properties).extend(obj);
      this._save();
      return this;
    };

    Config.prototype.unset = function() {
      var k, keys, _i, _len;
      keys = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      for (_i = 0, _len = keys.length; _i < _len; _i++) {
        k = keys[_i];
        this._unset_value(k);
      }
      this._save();
      return this;
    };

    return Config;

  })();

  module.exports = function(path) {
    return new Config(path);
  };

}).call(this);
