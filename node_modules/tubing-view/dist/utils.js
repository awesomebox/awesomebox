(function() {
  var find_file, is_path_in_root;

  String.prototype.startsWith = function(str) {
    var x, _i, _ref;
    if (this.length < str.length) {
      return false;
    }
    for (x = _i = 0, _ref = str.length; 0 <= _ref ? _i < _ref : _i > _ref; x = 0 <= _ref ? ++_i : --_i) {
      if (this[x] !== str[x]) {
        return false;
      }
    }
    return true;
  };

  find_file = function(needle, haystack) {
    var file, _i, _len;
    for (_i = 0, _len = haystack.length; _i < _len; _i++) {
      file = haystack[_i];
      if (file.filename.startsWith(needle) && (file.filename.length === needle.length || file.filename[needle.length] === '.')) {
        return file;
      }
    }
    return null;
  };

  is_path_in_root = function(root, path) {
    return require('path').relative(root.absolute_path, path).indexOf('..') === -1;
  };

  exports.resolve_path_from_root = function(root, paths, callback) {
    var step;
    if (!Array.isArray(paths)) {
      paths = [paths];
    }
    step = function(idx) {
      var p, path;
      if (idx === paths.length) {
        return callback();
      }
      path = paths[idx];
      p = root.join(path);
      return p.directory().readdir(function(err, files) {
        var f;
        if (files != null) {
          f = find_file(p.filename, files);
          if ((f != null) && is_path_in_root(root, f.absolute_path)) {
            return callback(null, f, path);
          }
        }
        return step(idx + 1);
      });
    };
    return step(0);
  };

  exports.resolve_path_from_root_sync = function(root, paths) {
    var f, p, path, _i, _len;
    if (!Array.isArray(paths)) {
      paths = [paths];
    }
    for (_i = 0, _len = paths.length; _i < _len; _i++) {
      path = paths[_i];
      p = root.join(path);
      try {
        f = find_file(p.filename, p.directory().readdir_sync());
        if ((f != null) && is_path_in_root(root, f.absolute_path)) {
          return f;
        }
      } catch (err) {

      }
    }
    return null;
  };

}).call(this);
