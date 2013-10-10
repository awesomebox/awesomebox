(function() {

  exports.dependencies = 'stylus';

  exports.extension = 'styl';

  exports.attr_types = {
    'text/stylus': 'styl'
  };

  exports.process = function(opts, callback) {
    return opts.dependencies.stylus.render(opts.text, {
      filename: opts.filename || '/path.styl'
    }, callback);
  };

}).call(this);
