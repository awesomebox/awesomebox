# Commandment

Commandline for node.js

## Installation
```
npm install commandment
```

## Usage

##### main.js
```javascript
var Commandment = require('commandment')
  , commands = new Commandment({name: 'my-app', command_dir: __dirname + '/commands'});

commands.before_execute(function(context, next) {
  context.hello_helper = function() {
    // You can call me from commands now
    return 'hello world';
  };
});

commands.after_execute(function(context, err, next) {
  if (err) return console.error(err.stack);
  context.log('Yay! Everything is fine');
  next();
});

commands.execute(process.argv);
```

Commands are just exported from files in the commands directory

##### commands/hello.js
```javascript
exports.hello = function(callback) {
  this.log(this.hello_helper());
  callback()
};

// There can be multiple per file
exports.hello_person = function(name, callback) {
  this.log('Hello ' + name);
  callback();
};
```

## License
Copyright (c) 2013 Matt Insler  
Licensed under the MIT license.
