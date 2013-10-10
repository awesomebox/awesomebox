(function() {
  var Source;

  Source = (function() {

    Source.define = function(method) {
      return new Source(method);
    };

    function Source(method) {
      this.method = method;
    }

    Source.prototype.publish_to = function(pipeline) {
      var emitter;
      emitter = function(cmd) {
        return pipeline.push(cmd);
      };
      return this.method(emitter);
    };

    return Source;

  }).call(this);

  module.exports = Source;

}).call(this);
