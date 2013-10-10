# tubing

Simple Pipelines

## Installation
```
npm install tubing
```

## Usage
```javascript
var tubing = require('tubing');

function readFile(cmd, done) {
  require('fs').readFile(cmd.path, function(err, data) {
    if (err) return done(err);
    cmd.content = data;
    done();
  });
}

function removeNewLines(cmd, done) {
  cmd.content = cmd.content.replace(/\n/g, '');
  done()
}

var TestPipeline = tubing.pipeline('Test Pipeline')
  .then(readFile)
  .then(removeNewLines);

var loggingSink = tubing.sink(function(err, cmd) {
  if (err) return console.log(err.stack);
  console.log(cmd);
});

var pipeline = TestPipeline.configure().publish_to(loggingSink);
pipeline.push({path: '/tmp/foo.txt'});
```

## License
Copyright (c) 2013 Matt Insler
Licensed under the MIT license.
