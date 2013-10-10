# tubing-view

View Pipeline

## Installation
```
npm install tubing-view
```

## Usage
```javascript
var mime = require('mime')
  , http = require('http')
  , ViewPipeline = require('tubing-view').ViewPipeline;

var pipeline = ViewPipeline.configure({
  path: {
    content: process.cwd() + '/content'
  }
}).publish_to(function(err, cmd) {
  function write_res(code, content, content_type) {
    cmd.res.writeHead(code, {
      'Content-Type': content_type ? mime.lookup(content_type) : 'text/plain',
      'Content-Length': content.length
    });
    cmd.res.end(content);
  }
  
  if (err) return write_res(500, err.stack);
  if (!cmd.content) return write_res(404, 'Not Found');
  
  write_res(200, cmd.content, cmd.content_type);
});

http.createServer(function(req, res) {
  pipeline.push({
    req: req,
    res: res
  });
}).listen(3000);
```

## License
Copyright (c) 2013 Matt Insler
Licensed under the MIT license.
