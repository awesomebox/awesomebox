(function() {
  var Definition, Pipeline, Q, index_of,
    __slice = [].slice;

  Q = require('q');

  index_of = function(arr, predicate) {
    var x, _i, _ref;
    for (x = _i = 0, _ref = arr.length; 0 <= _ref ? _i < _ref : _i > _ref; x = 0 <= _ref ? ++_i : --_i) {
      if (predicate(arr[x])) {
        return x;
      }
    }
    return -1;
  };

  Definition = (function() {

    function Definition(name, pipes, config_methods) {
      this.name = name;
      this.pipes = pipes != null ? pipes : [];
      this.config_methods = config_methods != null ? config_methods : [];
    }

    Definition.prototype.then = function() {
      var Pipe, pipes;
      pipes = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      if (pipes.length === 0) {
        throw new Error('Cannot call .then without passing in at least 1 pipe');
      }
      Pipe = require('./pipe');
      return new Definition(this.name, this.pipes.concat(Pipe.define.apply(Pipe, pipes)), this.config_methods = []);
    };

    Definition.prototype.insert = function() {
      var Pipe, hash, opts, pipe, pipes, x, _i;
      pipes = 2 <= arguments.length ? __slice.call(arguments, 0, _i = arguments.length - 1) : (_i = 0, []), opts = arguments[_i++];
      if (!((opts.before != null) || (opts.after != null) || (opts.instead_of != null))) {
        throw new Error('Pipeline#insert() takes before, after, or instead_of');
      }
      Pipe = require('./pipe');
      pipe = Pipe.define.apply(Pipe, pipes);
      hash = Pipe.define(opts.before || opts.after || opts.instead_of).hash;
      pipes = this.pipes.slice();
      x = index_of(pipes, function(p) {
        return p.hash === hash;
      });
      if (x !== -1) {
        if (opts.before != null) {
          pipes.splice(x, 0, pipe);
        } else if (opts.after != null) {
          pipes.splice(x + 1, 0, pipe);
        } else if (opts.instead_of != null) {
          pipes.splice(x, 1, pipe);
        }
      }
      return new Definition(this.name, pipes, this.config_methods);
    };

    Definition.prototype.remove = function() {
      var Pipe, hash, pipes;
      pipes = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      Pipe = require('./pipe');
      hash = Pipe.define(opts.before).hash;
      pipes = this.pipes.slice().filter(function(pipe) {
        return pipe.hash !== hash;
      });
      return new Definition(this.name, pipes, this.config_methods);
    };

    Definition.prototype.remove_nth = function() {
      var Pipe, hash, n, pipes, x;
      n = arguments[0], pipes = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      Pipe = require('./pipe');
      hash = Pipe.define(opts.before).hash;
      x = 0;
      pipes = this.pipes.slice().filter(function(pipe) {
        if (pipe.hash === hash && ++x === n) {
          return false;
        }
        return true;
      });
      return new Definition(this.name, pipes, this.config_methods);
    };

    Definition.prototype.configure = function(config) {
      var c, pipeline, _i, _len, _ref;
      if (typeof config === 'function') {
        this.config_methods.push(config);
        return this;
      }
      if (config == null) {
        config = {};
      }
      pipeline = new Pipeline(this, config);
      _ref = this.config_methods;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        c = _ref[_i];
        c(pipeline, config);
      }
      return pipeline;
    };

    return Definition;

  })();

  Pipeline = (function() {

    Pipeline.Definition = Definition;

    Pipeline.define = function(name) {
      return new Pipeline.Definition(name);
    };

    function Pipeline(definition, config) {
      this.definition = definition;
      this.config = config;
      this.pipes = Array.prototype.slice.call(this.definition.pipes);
      this.sinks = [];
    }

    Pipeline.prototype.without = function() {
      var Pipe, hash, pipes;
      pipes = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      Pipe = require('./pipe');
      hash = Pipe.define.apply(Pipe, pipes).hash;
      this.pipes = this.pipes.filter(function(p) {
        return p.hash !== hash;
      });
      return this;
    };

    Pipeline.prototype.without_nth = function() {
      var Pipe, hash, n, pipes, x;
      n = arguments[0], pipes = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      Pipe = require('./pipe');
      hash = Pipe.define.apply(Pipe, pipes).hash;
      x = 0;
      this.pipes = this.pipes.filter(function(p) {
        if (p.hash === hash) {
          ++x;
          return n !== x;
        }
        return true;
      });
      return this;
    };

    Pipeline.prototype.push = function(cmd) {
      var context, create_pipe_method, deferred, finish_pipeline, pipe, q, _i, _len, _ref,
        _this = this;
      deferred = Q.defer();
      finish_pipeline = function(err, data) {
        var s, _i, _j, _len, _len1, _ref, _ref1, _results;
        if (data == null) {
          data = cmd;
        }
        if (err != null) {
          deferred.reject(err);
          _ref = _this.sinks;
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            s = _ref[_i];
            s.process(context, err, data);
          }
          return;
        }
        deferred.resolve(data);
        _ref1 = _this.sinks;
        _results = [];
        for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
          s = _ref1[_j];
          _results.push(s.process(context, null, data));
        }
        return _results;
      };
      context = {
        Q: Q,
        defer: function() {
          return Q.defer();
        },
        config: this.config,
        pipeline: this,
        exit_pipeline: finish_pipeline
      };
      create_pipe_method = function(pipe) {
        return function(cmd) {
          return pipe.process(context, cmd);
        };
      };
      q = Q(cmd);
      _ref = this.pipes;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        pipe = _ref[_i];
        q = q.then(pipe.process.bind(pipe, context));
      }
      q.then(function(data) {
        return finish_pipeline(null, data);
      }, finish_pipeline);
      return deferred.promise;
    };

    Pipeline.prototype.publish_to = function(sink) {
      var Sink;
      Sink = require('./sink');
      if (!(sink instanceof Sink)) {
        sink = new Sink(sink);
      }
      this.sinks.push(sink);
      return this;
    };

    return Pipeline;

  }).call(this);

  Pipeline.prototype.__type__ = 'Pipeline';

  Pipeline.Definition.prototype.__type__ = 'Pipeline.Definition';

  module.exports = Pipeline;

}).call(this);
