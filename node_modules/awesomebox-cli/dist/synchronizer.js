(function() {
  var Synchronizer, async, syncr, walkabout;

  async = require('async');

  syncr = require('syncr');

  walkabout = require('walkabout');

  Synchronizer = (function() {

    function Synchronizer(client) {
      this.client = client;
    }

    Synchronizer.prototype.sync = function(sync_opts, callback) {
      var box, delta, manifest, opts,
        _this = this;
      sync_opts.root = walkabout(sync_opts.root);
      opts = {};
      if (sync_opts.root.join('.awesomeboxignore').exists_sync()) {
        opts.ignore_file = sync_opts.root.join('.awesomeboxignore').absolute_path;
      } else {
        opts.ignore = ['node_modules', 'bin'];
      }
      box = this.client.box(sync_opts.box);
      manifest = null;
      delta = null;
      sync_opts.metadata = {
        done: true
      };
      return async.waterfall([
        function(cb) {
          return syncr.create_manifest(sync_opts.root.absolute_path, opts, cb);
        }, function(m, cb) {
          manifest = m;
          return box.push({
            manifest: manifest
          }, cb);
        }, function(d, cb) {
          delta = d;
          if (delta === true) {
            return callback();
          }
          sync_opts.metadata.branch = delta.branch;
          return sync_opts.collect_metadata(function(err, meta) {
            var files_to_send, k, v;
            if (err != null) {
              return cb(err);
            }
            for (k in meta) {
              v = meta[k];
              sync_opts.metadata[k] = v;
            }
            files_to_send = delta.add.concat(delta.change);
            return async.eachSeries(files_to_send, function(path, send_cb) {
              var file_path;
              sync_opts.on_progress("Sending " + path + "...");
              file_path = sync_opts.root.join(path);
              return box.push({
                path: path,
                hash: manifest.files[path],
                branch: delta.branch,
                file: file_path.create_read_stream()
              }, function(err) {
                if (err != null) {
                  sync_opts.on_progress("Sending " + path + "... Error: " + err.message);
                  return send_cb(err);
                }
                sync_opts.on_progress("Sending " + path + "... Done");
                return send_cb();
              });
            }, cb);
          });
        }
      ], function(err) {
        if (err != null) {
          return callback(err);
        }
        return box.push(sync_opts.metadata, callback);
      });
    };

    return Synchronizer;

  })();

  module.exports = Synchronizer;

}).call(this);
