(function() {
  var ACCESSOR, ACTION, create_filter_predicate, filter_predicate, get_value, is_false, is_true, negate;

  exports.Sink = require('./sink');

  exports.Source = require('./source');

  exports.Pipe = require('./pipe');

  exports.Pipeline = require('./pipeline');

  exports.sink = exports.Sink.define.bind(null);

  exports.source = exports.Source.define.bind(null);

  exports.pipe = exports.Pipe.define.bind(null);

  exports.pipeline = exports.Pipeline.define.bind(null);

  get_value = function(obj, v) {
    var part, _i, _len, _ref;
    _ref = v.split('.');
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      part = _ref[_i];
      obj = obj[part];
      if (obj == null) {
        return null;
      }
    }
    return obj;
  };

  filter_predicate = function(accessor, predicate, action) {
    return function(cmd, done) {
      var v;
      v = accessor.call(this, cmd);
      try {
        if (predicate(v)) {
          return action.call(this, cmd, done);
        }
      } catch (err) {
        return done(err);
      }
      return done();
    };
  };

  ACCESSOR = {
    cmd: function(cmd) {
      return cmd;
    },
    config: function() {
      return this.config;
    }
  };

  ACTION = {
    exit_pipeline: function() {
      return this.exit_pipeline();
    }
  };

  negate = function(predicate) {
    return function(v) {
      return !predicate(v);
    };
  };

  is_true = function(predicate) {
    return function(v) {
      return predicate(v) === true;
    };
  };

  is_false = function(predicate) {
    return function(v) {
      return predicate(v) === false;
    };
  };

  create_filter_predicate = function(value) {
    var parts, predicate;
    if (typeof value === 'function') {
      return value;
    }
    if (typeof value === 'string') {
      parts = value.split(/\s+/).filter(function(a) {
        return (a != null) && a !== '';
      });
      if (parts.length === 1) {
        predicate = function(v) {
          return get_value(v, parts[0]) != null;
        };
      } else if (parts.length === 2) {
        parts[0] = parts[0].toLowerCase();
        if (parts[0] === 'not') {
          predicate = function(v) {
            return !(get_value(v, parts[1]) != null);
          };
        } else {
          throw new Error('Unsupported if clause modifier: ' + parts[0]);
        }
      }
      return predicate;
    }
    throw new Error('Unsupported if clause');
  };

  exports.exit_if = function(value) {
    var predicate;
    predicate = create_filter_predicate(value);
    return filter_predicate(ACCESSOR.cmd, predicate, ACTION.exit_pipeline);
  };

  exports.exit_unless = function(value) {
    var predicate;
    predicate = create_filter_predicate(value);
    return filter_predicate(ACCESSOR.cmd, negate(predicate), ACTION.exit_pipeline);
  };

  exports.exit_if_config = function(value) {
    var predicate;
    predicate = create_filter_predicate(value);
    return filter_predicate(ACCESSOR.config, predicate, ACTION.exit_pipeline);
  };

  exports.exit_unless_config = function(value) {
    var predicate;
    predicate = create_filter_predicate(value);
    return filter_predicate(ACCESSOR.config, negate(predicate), ACTION.exit_pipeline);
  };

  exports.exit_if_config_true = function(value) {
    var predicate;
    predicate = create_filter_predicate(value);
    return filter_predicate(ACCESSOR.config, is_true(predicate), ACTION.exit_pipeline);
  };

  exports.exit_unless_config_true = function(value) {
    var predicate;
    predicate = create_filter_predicate(value);
    return filter_predicate(ACCESSOR.config, negate(is_true(predicate)), ACTION.exit_pipeline);
  };

  exports.exit_if_config_false = function(value) {
    var predicate;
    predicate = create_filter_predicate(value);
    return filter_predicate(ACCESSOR.config, is_false(predicate), ACTION.exit_pipeline);
  };

  exports.exit_unless_config_false = function(value) {
    var predicate;
    predicate = create_filter_predicate(value);
    return filter_predicate(ACCESSOR.config, negate(is_false(predicate)), ACTION.exit_pipeline);
  };

}).call(this);
