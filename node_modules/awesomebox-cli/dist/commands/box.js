(function() {
  var Synchronizer, chalk, config, errors;

  chalk = require('chalk');

  errors = require('../errors');

  config = require('../config');

  Synchronizer = require('../synchronizer');

  exports.save = function(callback) {
    var box_config, client, create_box, get_box, get_message, no_box, save_code_to_box,
      _this = this;
    client = this.client.keyed();
    if (client == null) {
      return callback(errors.unauthorized());
    }
    box_config = config(process.cwd() + '/.awesomebox');
    get_box = function(cb) {
      var box;
      box = box_config.get('id', 'name');
      if (!((box.id != null) && (box.name != null))) {
        _this.log("It doesn't look like you've created a box for this project yet.");
        return no_box(cb);
      }
      return client.box(box.id).get(function(err, box) {
        if (err != null) {
          if (err.status_code !== 404) {
            return cb(err);
          }
          _this.log("Sorry, it looks like the box for this project no longer exists.");
          _this.log('');
          return no_box(cb);
        }
        return cb(null, box);
      });
    };
    create_box = function(cb) {
      return _this.prompt.get({
        properties: {
          name: {
            required: true
          }
        }
      }, function(err, data) {
        if (err != null) {
          return cb(err);
        }
        return client.boxes.create(data, function(err, box) {
          if (err != null) {
            return cb(err);
          }
          box_config.set(box);
          _this.log('');
          _this.log("Great! Now that you've created a box, we'll save your code to it.");
          _this.log('');
          return cb(null, box);
        });
      });
    };
    no_box = function(cb) {
      return client.boxes.list(function(err, boxes) {
        var b, x, _i, _len;
        if (err != null) {
          return cb(err);
        }
        if (boxes.length === 0) {
          _this.log("Let's fix that. Name your new box.");
          _this.log('');
          return create_box(cb);
        }
        _this.log("Are you saving a box that already exists? Maybe one of these?");
        _this.log('');
        x = 0;
        for (_i = 0, _len = boxes.length; _i < _len; _i++) {
          b = boxes[_i];
          _this.log("" + (++x) + ") " + b.name);
        }
        _this.log("" + (++x) + ") Create a new box");
        return _this.prompt.get({
          properties: {
            box: {
              required: true,
              type: 'number',
              conform: function(v) {
                return v > 0 && v <= boxes.length + 1;
              }
            }
          }
        }, function(err, data) {
          var box;
          if (err != null) {
            return cb(err);
          }
          _this.log('');
          if (data.box <= boxes.length) {
            box = boxes[data.box - 1];
            box_config.set(box);
            return cb(null, box);
          }
          _this.log("OK cool. Let's get that new box setup for you.");
          _this.log('');
          return create_box(cb);
        });
      });
    };
    get_message = function(cb) {
      _this.log('Leave a message to remind yourself of the changes you made.');
      _this.log('');
      return _this.prompt.get({
        properties: {
          message: {
            required: false
          }
        }
      }, function(err, data) {
        if (err != null) {
          return cb(err);
        }
        _this.log('');
        return cb(null, data.message);
      });
    };
    save_code_to_box = function(box, cb) {
      var synchronizer;
      _this.log("Preparing to save " + box.name + "...");
      _this.log('');
      synchronizer = new Synchronizer(client);
      return synchronizer.sync({
        box: box.id,
        root: process.cwd(),
        on_progress: function(msg) {
          return _this.log(msg);
        },
        collect_metadata: function(meta_cb) {
          return get_message(function(err, message) {
            if (err != null) {
              return meta_cb(err);
            }
            return meta_cb(null, {
              message: message
            });
          });
        }
      }, function(err, version) {
        if (err != null) {
          return cb(err);
        }
        if (version == null) {
          _this.log("All of your files are up to date. Horay!");
        } else {
          _this.log('');
          _this.log("All done saving " + box.name + "!");
          _this.log("We've created new version " + (chalk.cyan(version.name)) + " for you.");
          _this.log("You can see it at " + (chalk.cyan('http://' + version.domain)) + ".");
        }
        return cb();
      });
    };
    return get_box(function(err, box) {
      if (err != null) {
        return callback(err);
      }
      return save_code_to_box(box, callback);
    });
  };

  exports.load = function(box_name, box_version, callback) {
    var client, get_box, get_version, no_box, no_version,
      _this = this;
    if (typeof box_name === 'function') {
      callback = box_name;
      box_name = null;
      box_version = null;
    } else if (typeof box_version === 'function') {
      callback = box_version;
      box_version = null;
    }
    this.log("We're sorry! " + (chalk.cyan('awesomebox load')) + " isn't ready for action yet.");
    this.log("For now, go to http://www.awesomebox.co to download the code for a version.");
    return callback();
    client = this.client.keyed();
    if (client == null) {
      return callback(errors.unauthorized());
    }
    get_box = function(name, cb) {
      if (name == null) {
        return no_box(cb);
      }
      return client.box(name).get(function(err, box) {
        if (err != null) {
          return cb(err);
        }
        if (box != null) {
          return cb(null, box);
        }
        _this.log("Hmm, doesn't look like you have a box with that name.");
        _this.lob('');
        return no_box(cb);
      });
    };
    no_box = function(cb) {
      return client.boxes.list(function(err, boxes) {
        var b, x, _i, _len;
        if (err != null) {
          return cb(err);
        }
        if (boxes.length === 0) {
          _this.log("Doesn't look like you have any boxes to load.");
          return callback();
        }
        _this.log("Want to load one of these?");
        _this.log('');
        x = 0;
        for (_i = 0, _len = boxes.length; _i < _len; _i++) {
          b = boxes[_i];
          _this.log("" + (++x) + ") " + b.name);
        }
        return _this.prompt.get({
          properties: {
            box: {
              required: true,
              type: 'number',
              conform: function(v) {
                return v > 0 && v <= boxes.length;
              }
            }
          }
        }, function(err, data) {
          if (err != null) {
            return cb(err);
          }
          _this.log('');
          console.log('got box');
          return cb(null, boxes[data.box - 1]);
        });
      });
    };
    get_version = function(box, version, cb) {
      console.log('get_version', arguments);
      if (version == null) {
        return no_version(box, cb);
      }
      return client.box(box.id).version(version).get(function(err, box) {
        if (err != null) {
          return cb(err);
        }
        if (box != null) {
          return cb(null, box);
        }
        _this.log("Hmm, doesn't look like " + (chalk.magenta(box.name)) + " has that version.");
        _this.lob('');
        return no_version(box, cb);
      });
    };
    no_version = function(box, cb) {
      return client.box(box.id).versions.list(function(err, versions) {
        var v, x, _i, _len;
        if (err != null) {
          return cb(err);
        }
        console.log(versions);
        if (versions.length === 0) {
          _this.log("Doesn't look like " + box.name + " has any versions to load.");
          return callback();
        } else {
          _this.log("Want to load one of these?");
          _this.log('');
          x = 0;
          for (_i = 0, _len = versions.length; _i < _len; _i++) {
            v = versions[_i];
            _this.log("" + (++x) + ") " + v.name);
          }
          return callback();
        }
      });
    };
    return get_box(box_name, function(err, box) {
      if (err != null) {
        return callback(err);
      }
      console.log(box);
      console.log('call get_version');
      return get_version(box, box_version, function(err, version) {
        if (err != null) {
          return callback(err);
        }
        return console.log(version);
      });
    });
  };

}).call(this);
