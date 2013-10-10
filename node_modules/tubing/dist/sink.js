(function() {
  var Sink;

  Sink = (function() {

    Sink.define = function(method) {
      return new Sink(method);
    };

    function Sink(method) {
      this.method = method;
    }

    Sink.prototype.process = function(context, err, cmd) {
      return this.method.call(context, err, cmd);
    };

    return Sink;

  }).call(this);

  module.exports = Sink;

}).call(this);
