# betturl

Better URL handling

## Installation
```
npm install betturl
```

## Usage
```javascript
var betturl = require('betturl');
var parsed = betturl.parse('http://someurl.com');

// do something with parsed
```

## Methods

### betturl.parse(url, options = {})

Parse a URL.

The simplest form of this works very similar to the [URL module](http://nodejs.org/api/url.html) from the node.js core.

```javascript
> betturl.parse('http://www.google.com');
{
  url: 'http://www.google.com',   // the original url parsed
  protocol: 'http',
  host: 'www.google.com',
  port: 80,
  path: '/',
  query: '',
  hash: ''
}
```

betturl will also parse more complex URLs, like connection URLs, and infer the types of variables in the querystring.

```javascript
> betturl.parse('mongodb://matt.insler%40gmail.com:foobar@1.2.3.4:6000,4.3.2.1:8000/database-123?auto_reconnect=true&namespace=foo&timeout=3000');
{
  url: 'mongodb://matt.insler%40gmail.com:foobar@1.2.3.4:6000,4.3.2.1:8000/database-123?auto_reconnect=true&namespace=foo&timeout=3000',
  protocol: 'mongodb',
  hosts: [
    { host: '1.2.3.4', port: 6000 },
    { host: '4.3.2.1', port: 8000 }
  ],
  path: '/database-123',
  query: {
    auto_reconnect: true,
    namespace: 'foo',
    timeout: 3000
  },
  hash: '',
  auth: {
    user: 'matt.insler@gmail.com',
    password: 'foobar'
  }
}
```

##### Options

- **_parse_query_**
  Should the querystring be parsed into typed fields.
  By setting this to false, the query property will be a string.
  _Accepted values_: **true**, **false**
  _Default_: **true**

## License
Copyright (c) 2012 Matt Insler  
Licensed under the MIT license.
