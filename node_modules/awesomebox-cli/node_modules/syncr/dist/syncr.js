(function() {
  var Manifest;

  Manifest = exports.Manifest = require('./manifest');

  exports.compute_delta = Manifest.compute_delta;

  exports.hash_file = Manifest.hash_file;

  exports.create_manifest = function(root, opts, cb) {
    if (typeof opts === 'function') {
      cb = opts;
      opts = {};
    }
    return new Manifest(root, opts).create(cb);
  };

}).call(this);
