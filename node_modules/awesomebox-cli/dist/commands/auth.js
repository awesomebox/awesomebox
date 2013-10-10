(function() {
  var login_attempt_messages;

  login_attempt_messages = ["That doesn't seem right. Care to try again?", "Hmmmm, still not right...", "Why don't you go look up that password and come back later."];

  exports.login = function(cb) {
    var _ref,
      _this = this;
    if ((_ref = this._login_count) == null) {
      this._login_count = 0;
    }
    return this.prompt.get({
      properties: {
        email: {
          required: true
        },
        password: {
          required: true,
          hidden: true
        }
      }
    }, function(err, data) {
      var client;
      if (err != null) {
        return cb(err);
      }
      client = _this.client(data);
      return client.me.get(function(err, user) {
        if ((err != null) && err.status_code === 401) {
          if (++_this._login_count === 3) {
            _this.log('');
            _this.error(login_attempt_messages[_this._login_count - 1]);
            return cb();
          }
          _this.log('');
          _this.error(login_attempt_messages[_this._login_count - 1]);
          _this.log('');
          return process.nextTick(function() {
            return exports.login.call(_this, cb);
          });
        }
        if (err != null) {
          return cb(err);
        }
        _this.login(user);
        _this.log('');
        _this.log("Welcome back! It's been way too long.");
        return cb();
      });
    });
  };

  exports.logout = function(cb) {
    this.logout();
    this.log("We're really sad to see you go. =-(");
    return cb();
  };

}).call(this);
