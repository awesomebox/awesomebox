# exports.resolve_content_type = (cmd, done) ->
#   try
#     cmd.parsed = betturl.parse(cmd.path)
#   
#     unless cmd.content_type?
#       content_type = mime.lookup(cmd.parsed.path)
#       content_type = cmd.req.accepted[0].value if content_type is 'application/octet-stream' and cmd.req?
#       cmd.content_type = mime.extension(content_type)
#     
#     try
#       cmd.mime_type = mime.lookup(cmd.content_type)
#     catch err
#       cmd.mime_type = 'text/plain'
#     cmd.mime_charset = mime.charsets.lookup(cmd.mime_type)
#   catch err
#     return done(err)
#   
#   done()

assert = require 'assert'
TubingView = require '../'

test_path = (path, done) ->
  cmd = {path: path}
  
  TubingView.resolve_content_type cmd, (err) ->
    # console.log cmd
    return done(err) if err?
    assert.equal(cmd.content_type, 'html')
    done()
  

describe 'resolve_content_type', ->
  it 'identifies HTML content-type', (done) -> test_path('/foo.html?bar=baz' , done)
  it 'identifies HTML content-type', (done) -> test_path('/foo?bar=baz' , done)
