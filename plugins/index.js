require('coffee-script');
var fs = require('fs')
  , path = require('path')
  , async = require('async');

var plugins = [];

fs.readdirSync(__dirname).forEach(function(file) {
  var filename = path.join(__dirname, file);
  
  if (filename !== __filename && ['.js', '.coffee'].indexOf(path.extname(file)) !== -1) {
    plugins.push(require(filename));
  }
});

module.exports = function(context, done) {
  async.eachSeries(plugins, function(plugin, cb) {
    plugin(context, cb);
  }, done);
};
