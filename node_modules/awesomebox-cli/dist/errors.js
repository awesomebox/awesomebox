(function() {
  var UnauthorizedError,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  UnauthorizedError = (function(_super) {

    __extends(UnauthorizedError, _super);

    function UnauthorizedError() {
      UnauthorizedError.__super__.constructor.call(this);
      Error.captureStackTrace(this, arguments.callee);
      this.name = 'UnauthorizedError';
    }

    return UnauthorizedError;

  })(Error);

  exports.UnauthorizedError = UnauthorizedError;

  exports.unauthorized = function() {
    return new UnauthorizedError();
  };

  exports.is_unauthorized = function(err) {
    if ((err != null ? err.status_code : void 0) === 401) {
      return true;
    }
    if ((err != null ? err.name : void 0) === 'UnauthorizedError') {
      return true;
    }
    return false;
  };

}).call(this);
