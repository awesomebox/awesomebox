(function() {

  exports.dependencies = ['marked', 'pygmentize-bundled'];

  exports.extensions = ['markdown', 'md'];

  exports.process = function(opts, callback) {
    var marked, pygmentize;
    marked = opts.dependencies.marked;
    pygmentize = opts.dependencies['pygmentize-bundled'];
    marked.setOptions({
      highlight: function(code, lang, callback) {
        return pygmentize({
          lang: lang,
          format: 'html'
        }, code, function(err, result) {
          if (err != null) {
            return callback(err);
          }
          return callback(null, result.toString());
        });
      }
    });
    return process.nextTick(function() {
      try {
        return callback(null, marked(opts.text));
      } catch (err) {
        return callback(err);
      }
    });
  };

}).call(this);
