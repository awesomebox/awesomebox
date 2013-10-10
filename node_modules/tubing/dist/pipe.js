(function() {
  var MethodPipe, ParallelPipe, Pipe, PipelinePipe, Q, crypto,
    __slice = [].slice,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  Q = require('q');

  crypto = require('crypto');

  Pipe = (function() {

    function Pipe() {}

    Pipe.define = function() {
      var TempType, pipes, x, _i, _ref;
      pipes = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      for (x = _i = 0, _ref = pipes.length; 0 <= _ref ? _i < _ref : _i > _ref; x = 0 <= _ref ? ++_i : --_i) {
        if (pipes[x].__type__ === 'Pipeline.Definition') {
          pipes[x] = new PipelinePipe(pipes[x]);
        } else if (pipes[x].__type__ !== 'Pipe') {
          if (Array.isArray(pipes[x])) {
            TempType = MethodPipe.bind.apply(MethodPipe, [null].concat(pipes[x]));
            pipes[x] = new TempType();
          } else {
            pipes[x] = new MethodPipe(pipes[x]);
          }
        }
      }
      if (pipes.length > 1) {
        return new ParallelPipe(pipes);
      }
      return pipes[0];
    };

    return Pipe;

  })();

  Pipe.prototype.__type__ = 'Pipe';

  MethodPipe = (function(_super) {

    __extends(MethodPipe, _super);

    function MethodPipe() {
      var args, hash, method;
      method = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      this.method = method;
      this.args = args;
      hash = crypto.createHash('sha1').update(this.method.toString());
      if ((args != null) && args.length > 0) {
        hash.update(JSON.stringify(this.args));
      }
      this.hash = hash.digest('hex');
    }

    MethodPipe.prototype.process = function(context, cmd) {
      var d, handle_error, method, ret,
        _this = this;
      d = Q.defer();
      if (Array.isArray(cmd)) {
        cmd = cmd[0];
      }
      handle_error = function(err) {
        err.tubing = {
          pipe: _this,
          pipeline: context.pipeline
        };
        if (err != null) {
          return d.reject(err);
        }
      };
      if ((this.args != null) && this.args.length > 0) {
        method = this.method.apply(null, this.args);
      } else {
        method = this.method;
      }
      ret = method.call(context, cmd, function(err, data) {
        if (err != null) {
          return handle_error(err);
        }
        return d.resolve(data != null ? data : cmd);
      });
      if ((ret != null) && Q.isPromise(ret)) {
        d.resolve(ret);
      }
      return d.promise;
    };

    return MethodPipe;

  })(Pipe);

  ParallelPipe = (function(_super) {

    __extends(ParallelPipe, _super);

    function ParallelPipe(pipes) {
      this.pipes = pipes;
      this.hash = this.pipes.map(function(p) {
        return p.hash;
      }).join();
    }

    ParallelPipe.prototype.process = function(context, cmd) {
      return Q.all(this.pipes.map(function(p) {
        return p.process(context, cmd);
      }));
    };

    return ParallelPipe;

  })(Pipe);

  PipelinePipe = (function(_super) {

    __extends(PipelinePipe, _super);

    function PipelinePipe(pipeline_definition) {
      this.pipeline_definition = pipeline_definition;
      this.hash = this.pipeline_definition.pipes.map(function(p) {
        return p.hash;
      }).join();
    }

    PipelinePipe.prototype.process = function(context, cmd) {
      var instance;
      instance = this.pipeline_definition.configure(context.config);
      return instance.push(cmd);
    };

    return PipelinePipe;

  })(Pipe);

  module.exports = Pipe;

}).call(this);
