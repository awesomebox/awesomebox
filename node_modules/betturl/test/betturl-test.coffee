require 'should'
assert = require 'assert'
betturl = require '../dist/betturl'

describe 'betturl', ->
  describe '#parse', ->
    it 'should parse standard URLs', ->
      url = 'http://www.facebook.com'
      parsed = betturl.parse(url)
      
      parsed.should.have.property 'url', url
      parsed.should.have.property 'protocol', 'http'
      parsed.should.have.property 'host', 'www.facebook.com'
      parsed.should.have.property 'port', 80
      parsed.should.have.property('hosts').with.lengthOf(1)
      parsed.hosts[0].should.have.property 'host', 'www.facebook.com'
      parsed.hosts[0].should.have.property 'port', 80
      parsed.should.have.property 'path', '/'
    
    it 'should parse partial URLs', ->
      url = '/foo/bar/baz?a=b'
      parsed = betturl.parse(url)
      
      parsed.should.have.property 'url', url
      parsed.should.have.property 'path', '/foo/bar/baz'
      parsed.query.should.have.property 'a', 'b'
    
    it 'should parse querystrings after a /', ->
      url = '/?foo=bar'
      
      parsed = betturl.parse(url)
      
      parsed.should.have.property 'url', url
      parsed.should.have.property 'path', '/'
      parsed.query.should.have.property 'foo', 'bar'
    
    it 'should parse partial URLs with a host', ->
      url = 'google.com/foo/bar/baz?a=b'
      parsed = betturl.parse(url)
      
      parsed.should.have.property 'url', url
      parsed.should.have.property 'path', '/foo/bar/baz'
      parsed.query.should.have.property 'a', 'b'
    
    it 'should parse URLs with a user/password', ->
      url = 'https://user:password@www.facebook.com'
      parsed = betturl.parse(url)
      
      parsed.should.have.property 'url', url
      parsed.should.have.property 'protocol', 'https'
      parsed.should.have.property 'host', 'www.facebook.com'
      parsed.should.have.property 'port', 443
      parsed.should.have.property('hosts').with.lengthOf(1)
      parsed.hosts[0].should.have.property 'host', 'www.facebook.com'
      parsed.hosts[0].should.have.property 'port', 443
      parsed.should.have.property 'path', '/'
      parsed.auth.should.have.property 'user', 'user'
      parsed.auth.should.have.property 'password', 'password'
      
    it 'should parse a complex connection string', ->
      url = 'mongodb://hello:world@1.2.3.4:6000,2.3.4.5:8000/this/is/my/path?auto_reconnect=true&timeout=3000&prefix=test:&hello#foo-bar'
      parsed = betturl.parse(url)
      
      parsed.should.have.property 'url', url
      parsed.should.have.property 'protocol', 'mongodb'
      parsed.should.not.have.property 'host'
      parsed.should.not.have.property 'port'
      parsed.should.have.property('hosts').with.lengthOf(2)
      parsed.hosts[0].should.have.property 'host', '1.2.3.4'
      parsed.hosts[0].should.have.property 'port', 6000
      parsed.hosts[1].should.have.property 'host', '2.3.4.5'
      parsed.hosts[1].should.have.property 'port', 8000
      parsed.should.have.property 'path', '/this/is/my/path'
      parsed.auth.should.have.property 'user', 'hello'
      parsed.auth.should.have.property 'password', 'world'
      parsed.query.should.have.property 'auto_reconnect', true
      parsed.query.should.have.property 'timeout', 3000
      parsed.query.should.have.property 'prefix', 'test:'
      parsed.query.should.have.property 'hello', true
      parsed.should.have.property 'hash', 'foo-bar'
    
    it 'should not parse query when parse_query is false', ->
      url = 'http://foo.com/bar?yay=true'
      parsed = betturl.parse(url, parse_query: false)
      
      parsed.should.have.property 'query', 'yay=true'

    it 'should parse empty usernames', ->
      url = 'http://:password@foo.com'
      parsed = betturl.parse(url)
      
      parsed.should.have.property 'url', url
      parsed.should.have.property 'protocol', 'http'
      parsed.should.have.property 'host', 'foo.com'
      parsed.should.have.property 'path', '/'
      parsed.auth.should.have.property 'user', ''
      parsed.auth.should.have.property 'password', 'password'
