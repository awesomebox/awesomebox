(function() {

  exports.dependencies = 'coffee-script';

  exports.extension = 'coffee';

  exports.attr_types = {
    'text/coffeescript': 'coffee'
  };

  exports.process = function(opts, callback) {
    return process.nextTick(function() {
      try {
        return callback(null, opts.dependencies['coffee-script'].compile(opts.text, {
          bare: true
        }));
      } catch (err) {
        return callback(err);
      }
    });
  };

}).call(this);
