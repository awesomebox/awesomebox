(function() {
  var remove_comments;

  exports.dependencies = 'react-tools';

  exports.extension = 'jsx';

  exports.attr_types = {
    'text/jsx': 'jsx'
  };

  remove_comments = function(v) {
    var idx;
    while ((idx = v.indexOf('/*')) !== -1) {
      v = v.slice(v.indexOf('*/', idx) + 2);
    }
    return v;
  };

  exports.process = function(opts, callback) {
    opts.text = '/** @jsx React.DOM */\n' + remove_comments(opts.text);
    return process.nextTick(function() {
      try {
        return callback(null, opts.dependencies['react-tools'].transform(opts.text));
      } catch (err) {
        return callback(err);
      }
    });
  };

}).call(this);
