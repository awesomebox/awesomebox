(function() {

  exports.dependencies = 'sass';

  exports.extensions = ['sass', 'scss'];

  exports.attr_types = {
    'text/sass': 'sass',
    'text/scss': 'scss'
  };

  exports.process = function(opts, callback) {
    return process.nextTick(function() {
      try {
        return callback(null, opts.dependencies.sass.render(opts.text));
      } catch (err) {
        return callback(err);
      }
    });
  };

}).call(this);
