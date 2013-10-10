(function() {
  var PATH, fs, mkdirp, rimraf, util, walkabout, _,
    __slice = [].slice;

  fs = require('fs');

  util = require('util');

  mkdirp = require('mkdirp');

  PATH = require('path');

  _ = require('underscore');

  rimraf = require('rimraf');

  walkabout = (function() {

    function walkabout(path) {
      if (path == null) {
        path = process.cwd();
      }
      this.path = PATH.normalize(path.toString());
      this.absolute_path = PATH.resolve(this.path);
      this.dirname = PATH.dirname(this.path);
      this.extension = PATH.extname(this.path);
      this.filename = PATH.basename(this.path);
      this.basename = PATH.basename(this.path, this.extension);
      this.extension = this.extension.replace(/^\.+/, '');
    }

    walkabout.is_walkabout = function(candidate) {
      return (candidate.path != null) && (candidate.dirname != null) && (candidate.filename != null) && (candidate.basename != null);
    };

    walkabout.prototype.join = function() {
      var subpaths;
      subpaths = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      subpaths = subpaths.map(function(p) {
        if (walkabout.is_walkabout(p)) {
          return p.path;
        } else {
          return p;
        }
      });
      return new walkabout(PATH.join.apply(PATH, [this.path].concat(__slice.call(subpaths))));
    };

    walkabout.prototype.toString = function() {
      return this.path;
    };

    walkabout.prototype.require = function() {
      return require(this.absolute_path);
    };

    walkabout.prototype.exists = function(callback) {
      return (fs.exists || PATH.exists)(this.absolute_path, callback);
    };

    walkabout.prototype.exists_sync = function() {
      return (fs.existsSync || PATH.existsSync)(this.absolute_path);
    };

    walkabout.prototype.create_read_stream = function() {
      return fs.createReadStream(this.absolute_path);
    };

    walkabout.prototype.create_write_stream = function() {
      return fs.createWriteStream(this.absolute_path);
    };

    walkabout.prototype.link = function(dest, callback) {
      return fs.link(this.absolute_path, (walkabout.is_walkabout(dest) ? dest.path : dest), callback);
    };

    walkabout.prototype.link_sync = function(dest) {
      return fs.linkSync(this.absolute_path, (walkabout.is_walkabout(dest) ? dest.path : dest));
    };

    walkabout.prototype.symlink = function(dest, type, callback) {
      if (typeof type === 'function') {
        callback = type;
        type = 'file';
      }
      return fs.symlink(this.absolute_path, (walkabout.is_walkabout(dest) ? dest.path : dest), type, callback);
    };

    walkabout.prototype.symlink_sync = function(dest, type) {
      if (type == null) {
        type = 'file';
      }
      return fs.symlinkSync(this.absolute_path, (walkabout.is_walkabout(dest) ? dest.path : dest), type);
    };

    walkabout.prototype.mkdir = function(mode, callback) {
      if (typeof mode === 'function') {
        callback = mode;
        mode = 0x1ff;
      }
      return fs.mkdir(this.absolute_path, mode, callback);
    };

    walkabout.prototype.mkdir_sync = function(mode) {
      if (mode == null) {
        mode = 0x1ff;
      }
      return fs.mkdirSync(this.absolute_path, mode);
    };

    walkabout.prototype.mkdirp = function(mode, callback) {
      if (typeof mode === 'function') {
        callback = mode;
        mode = 0x1ff;
      }
      return mkdirp.sync(this.absolute_path, mode, callback);
    };

    walkabout.prototype.mkdirp_sync = function(mode) {
      if (mode == null) {
        mode = 0x1ff;
      }
      return mkdirp.sync(this.absolute_path, mode);
    };

    walkabout.prototype.readdir = function(callback) {
      var _this = this;
      return fs.readdir(this.absolute_path, function(err, files) {
        if (err != null) {
          return callback(err);
        }
        return callback(err, files.map(function(f) {
          return _this.join(f);
        }));
      });
    };

    walkabout.prototype.readdir_sync = function() {
      var _this = this;
      return fs.readdirSync(this.absolute_path).map(function(f) {
        return _this.join(f);
      });
    };

    walkabout.prototype.readlink = function(callback) {
      return fs.readlink(this.absolute_path, callback);
    };

    walkabout.prototype.readlink_sync = function() {
      return fs.readlinkSync(this.absolute_path);
    };

    walkabout.prototype.realpath = function(cache, callback) {
      if (typeof cache === 'function') {
        callback = cache;
        cache = void 0;
      }
      return fs.realpath(this.absolute_path, cache, callback);
    };

    walkabout.prototype.realpath_sync = function(cache) {
      if (cache == null) {
        cache = void 0;
      }
      return fs.realpathSync(this.absolute_path, cache);
    };

    walkabout.prototype.read_file = function(encoding, callback) {
      if (typeof encoding === 'function') {
        callback = encoding;
        encoding = 'utf8';
      }
      return fs.readFile(this.absolute_path, encoding, callback);
    };

    walkabout.prototype.read_file_sync = function(encoding) {
      if (encoding == null) {
        encoding = 'utf8';
      }
      return fs.readFileSync(this.absolute_path, encoding);
    };

    walkabout.prototype.stat = function(callback) {
      return fs.stat(this.absolute_path, callback);
    };

    walkabout.prototype.stat_sync = function() {
      return fs.statSync(this.absolute_path);
    };

    walkabout.prototype.write_file = function(data, encoding, callback) {
      if (typeof encoding === 'function') {
        callback = encoding;
        encoding = 'utf8';
      }
      return fs.writeFile(this.absolute_path, data, encoding, callback);
    };

    walkabout.prototype.write_file_sync = function(data, encoding) {
      if (encoding == null) {
        encoding = 'utf8';
      }
      return fs.writeFileSync(this.absolute_path, data, encoding);
    };

    walkabout.prototype.unlink = function(callback) {
      return fs.unlink(this.absolute_path, callback);
    };

    walkabout.prototype.unlink_sync = function() {
      return fs.unlinkSync(this.absolute_path);
    };

    walkabout.prototype.rm_rf = function(callback) {
      return rimraf(this.absolute_path, callback);
    };

    walkabout.prototype.rm_rf_sync = function() {
      return rimraf.sync(this.absolute_path);
    };

    walkabout.prototype.is_directory_empty = function(callback) {
      return this.readdir(function(err, files) {
        if ((err != null) && 'ENOENT' !== err.code) {
          return callback(err);
        }
        return callback(null, files.length === 0);
      });
    };

    walkabout.prototype.is_directory_empty_sync = function() {
      try {
        return this.readdir_sync().length === 0;
      } catch (e) {
        if ((e != null) && 'ENOENT' !== e.code) {
          throw e;
        }
      }
      return false;
    };

    walkabout.prototype.copy = function(to, callback) {
      var src;
      src = this;
      return src.exists(function(err, exists) {
        var dest;
        if (err != null) {
          return callback(err);
        }
        if (!exists) {
          return callback(new Error("File " + src + " does not exist."));
        }
        dest = walkabout.is_walkabout(to) ? to : new walkabout(to);
        return dest.exists(function(err, exists) {
          var input, output;
          if (err != null) {
            return callback(err);
          }
          if (exists) {
            return callback(new Error("File " + to + " already exists."));
          }
          input = src.create_read_stream();
          output = dest.create_write_stream();
          return util.pump(input, output, callback);
        });
      });
    };

    walkabout.prototype.copy_sync = function(to) {
      var dest;
      if (!this.exists_sync()) {
        throw new Error("File " + this + " does not exist.");
      }
      dest = walkabout.is_walkabout(to) ? to : new walkabout(to);
      if (dest.exists_sync()) {
        throw new Error("File " + to + " already exists.");
      }
      return dest.write_file_sync(this.read_file_sync());
    };

    walkabout.prototype.is_directory = function(callback) {
      return this.stat(function(err, stats) {
        return callback(err, stats != null ? stats.isDirectory() : null);
      });
    };

    walkabout.prototype.is_directory_sync = function() {
      return this.stat_sync().isDirectory();
    };

    walkabout.prototype.is_absolute = function() {
      return this.path[0] === '/';
    };

    walkabout.prototype.ls_sync = function(opts) {
      var ext, files, sub_files, _filter, _ref;
      if (opts == null) {
        opts = {};
      }
      if ((_ref = opts.filter) == null) {
        opts.filter = function() {
          return true;
        };
      }
      if (opts.extensions) {
        ext = _(opts.extensions).inject((function(o, e) {
          o[e] = 1;
          return o;
        }), {});
        _filter = opts.filter;
        opts.filter = function(p) {
          if (ext[p.extension] == null) {
            return false;
          }
          return _filter(p);
        };
        delete opts.extensions;
      }
      files = this.readdir_sync();
      if (opts.recursive) {
        sub_files = _.chain(files).collect(function(f) {
          try {
            if (f.is_directory_sync()) {
              return f.ls_sync(opts);
            }
          } catch (err) {

          }
        }).flatten().compact().value();
        Array.prototype.push.apply(files, sub_files);
      }
      return files.filter(opts.filter);
    };

    walkabout.prototype.directory = function() {
      return new walkabout(this.dirname);
    };

    return walkabout;

  })();

  module.exports = function(path) {
    return new walkabout(path);
  };

  module.exports.walkabout = walkabout;

}).call(this);
