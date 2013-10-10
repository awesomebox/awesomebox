(function() {

  exports.dependencies = function(engine) {
    return ['consolidate', engine];
  };

  exports.extensions = ['atpl', 'dust', 'eco', 'ect', 'ejs', 'haml', 'haml-coffee', 'handlebars', 'jade', 'jazz', 'jqtpl', 'just', 'liquor', 'mustache', 'qejs', 'swig', 'templayed', 'toffee', 'underscore', 'walrus', 'whiskers'];

  exports.process = function(opts, callback) {
    return opts.dependencies.consolidate[opts.engine].render(opts.text, opts.data, callback);
  };

}).call(this);
