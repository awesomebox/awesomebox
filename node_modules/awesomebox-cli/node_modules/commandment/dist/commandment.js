(function() {
  var Commandment, async, chalk, colors, fs, k, levels, logger, nopt, path, prompt, v, winston, _ref, _ref1;

  fs = require('fs');

  nopt = require('nopt');

  path = require('path');

  async = require('async');

  chalk = require('chalk');

  prompt = require('prompt');

  winston = require('winston');

  winston.cli();

  levels = {};

  _ref = winston.config.cli.levels;
  for (k in _ref) {
    v = _ref[k];
    levels[k] = v;
  }

  colors = {};

  _ref1 = winston.config.cli.colors;
  for (k in _ref1) {
    v = _ref1[k];
    colors[k] = v;
  }

  logger = new winston.Logger({
    transports: [new winston.transports.Console()]
  });

  logger.cli();

  Commandment = (function() {

    function Commandment(opts) {
      var file, _i, _len, _ref2, _ref3, _ref4, _ref5;
      this._properties = {};
      this.name = opts.name;
      if (opts.command_dir != null) {
        this.commands = {};
        _ref2 = fs.readdirSync(opts.command_dir);
        for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
          file = _ref2[_i];
          if (!((_ref3 = file[0]) === '.' || _ref3 === '_')) {
            _ref4 = require(path.join(opts.command_dir, file));
            for (k in _ref4) {
              v = _ref4[k];
              this.commands[k] = v;
            }
          }
        }
      }
      if ((_ref5 = this.commands) == null) {
        this.commands = opts.commands;
      }
      this.filters = {
        before: [],
        after: []
      };
    }

    Commandment.prototype._parse_args = function(argv) {
      var args, data, opts;
      opts = nopt(argv);
      args = Array.prototype.slice.call(opts.argv.remain);
      delete opts.argv;
      data = {
        opts: opts
      };
      if (!(args.length > 0)) {
        return data;
      }
      data.name = args.shift();
      data.args = args;
      data.command = this.commands[data.name];
      return data;
    };

    Commandment.prototype._before_execute = function(context, callback) {
      return async.eachSeries(this.filters.before, function(filter, cb) {
        return filter(context, cb);
      }, callback);
    };

    Commandment.prototype._after_execute = function(context, err, callback) {
      return async.eachSeries(this.filters.after, function(filter, cb) {
        return filter(context, err, cb);
      }, callback);
    };

    Commandment.prototype._execute_command = function(data, callback) {
      var args, command, context, name, opts,
        _this = this;
      name = data.name, args = data.args, opts = data.opts, command = data.command;
      if (levels[name] == null) {
        levels[name] = 10;
        colors[name] = 'magenta';
        logger.setLevels(levels);
        winston.addColors(colors);
      }
      prompt.message = chalk[colors[name]](name);
      prompt.start();
      context = {
        command: name,
        params: args || [],
        opts: opts,
        properties: this._properties,
        get: this.get.bind(this),
        set: function() {
          _this.set.apply(_this, arguments);
          return context;
        },
        log: logger.log.bind(logger, name),
        error: logger.error.bind(logger),
        logger: logger,
        prompt: prompt
      };
      return this._before_execute(context, function(err) {
        return command.apply(context, context.params.concat(function(err) {
          return _this._after_execute(context, err, function(err) {
            return typeof callback === "function" ? callback(err) : void 0;
          });
        }));
      });
    };

    Commandment.prototype.before_execute = function(cb) {
      this.filters.before.push(cb);
      return this;
    };

    Commandment.prototype.after_execute = function(cb) {
      this.filters.after.push(cb);
      return this;
    };

    Commandment.prototype.get = function(key) {
      return this._properties[key];
    };

    Commandment.prototype.set = function(vals) {
      for (k in vals) {
        v = vals[k];
        this._properties[k] = v;
      }
      return this;
    };

    Commandment.prototype.execute = function(argv) {
      var callback, data;
      data = this._parse_args(argv);
      callback = function() {
        return process.exit(0);
      };
      if (data.command != null) {
        return this._execute_command(data, callback);
      }
      if (((data.name != null) && (this.commands.help != null)) || (!(data.name != null) && !(this.commands.__default__ != null))) {
        return this._execute_command({
          name: 'help',
          opts: data.opts,
          command: this.commands.help
        }, callback);
      }
      if (!(data.name != null) && (this.commands.__default__ != null)) {
        return this._execute_command({
          name: this.name,
          opts: data.opts,
          command: this.commands.__default__
        }, callback);
      }
      return process.exit(1);
    };

    return Commandment;

  })();

  module.exports = Commandment;

}).call(this);
