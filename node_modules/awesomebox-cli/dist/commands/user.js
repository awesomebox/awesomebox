(function() {
  var chalk, errors;

  chalk = require('chalk');

  errors = require('../errors');

  exports.reserve = function(cb) {
    var _this = this;
    return this.prompt.get({
      properties: {
        email: {
          required: true
        }
      }
    }, function(err, data) {
      var client;
      if (err != null) {
        return cb(err);
      }
      client = _this.client();
      return client.users.reserve(data, function(err, user) {
        if (err != null) {
          return cb(err);
        }
        _this.log('');
        _this.log("Awesome! We've reserved you a spot.");
        _this.log("Sit tight and we'll send you an email when awesomebox is ready to go!");
        return cb();
      });
    });
  };

  exports.redeem = function(cb) {
    var _this = this;
    return this.prompt.get({
      properties: {
        email: {
          required: true
        },
        reservation: {
          required: true
        }
      }
    }, function(err, data) {
      var client;
      if (err != null) {
        return cb(err);
      }
      client = _this.client();
      return client.users.redeem(data, function(err, user) {
        var _ref;
        if ((err != null) && ((_ref = err.body) != null ? _ref.error : void 0) !== 'Required field: password') {
          return cb(err);
        }
        _this.log('');
        _this.log("Great! We found your reservation.");
        _this.log("You'll have to create a password now.");
        _this.log('');
        return _this.prompt.get({
          properties: {
            password: {
              required: true,
              hidden: true
            }
          }
        }, function(err, data2) {
          if (err != null) {
            return cb(err);
          }
          data.password = data2.password;
          return client.users.redeem(data, function(err, user) {
            if (err != null) {
              return cb(err);
            }
            _this.log('');
            _this.log('Splendiforous!');
            _this.log("Well isn't this wonderful news! We invited you in and you came. Oh happy day!");
            _this.log('');
            _this.log('Welcome to ' + chalk.blue.bold('awesomebox') + '!!!');
            _this.log('');
            _this.log("Now that you're a user, why don't you try creating a new box.");
            _this.log("Just type " + (chalk.cyan('awesomebox save')) + " from your project folder to get started.");
            _this.log('');
            _this.log(chalk.cyan('awesomebox save') + chalk.gray(" will create a new box on awesomebox.es and save"));
            _this.log(chalk.gray("your current work on the server."));
            _this.login(user);
            return cb();
          });
        });
      });
    });
  };

  exports.me = function(callback) {
    var client,
      _this = this;
    client = this.client.keyed();
    if (client == null) {
      return callback(errors.unauthorized());
    }
    return client.me.get(function(err, user) {
      var line, _i, _len, _ref;
      if (err != null) {
        return callback(err);
      }
      _ref = JSON.stringify(user, null, 2).split('\n');
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        line = _ref[_i];
        _this.log(line);
      }
      return callback();
    });
  };

}).call(this);
