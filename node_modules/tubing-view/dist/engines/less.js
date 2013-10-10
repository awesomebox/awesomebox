(function() {

  exports.dependencies = 'recess';

  exports.extension = 'less';

  exports.attr_types = {
    'text/less': 'less'
  };

  exports.process = function(opts, callback) {
    var Recess, instance;
    Recess = opts.dependencies.recess.Constructor;
    instance = new Recess();
    instance.options.compile = true;
    instance.path = opts.filename || '/path.less';
    instance.data = opts.text;
    instance.callback = function() {
      if (instance.errors.length > 0) {
        return callback(new Error(instance.errors[0].message));
      }
      return callback(null, instance.output.join('\n'));
    };
    return instance.parse();
  };

}).call(this);
