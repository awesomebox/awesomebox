Awesomebox = require '../lib/awesomebox'

print = -> console.log arguments

# client = new Awesomebox()
# client.user.create {email: 'matt.insler@gmail.com'}, (err, api_key) ->
#   return console.log(err.message) if err?
#   
#   client = new Awesomebox(api_key: api_key)
#   client.user.get(print)

client = new Awesomebox(base_url: 'http://localhost:8000', api_key: 'bc7ac927f302ffed68b16d546c95daa8b8575257541c2c1867fd0815d76a808636bad0700e996ebeb93e4b37ff9d97f3cb6de3d884c58256b790a62d6b7696e8')
# client.me.get(print)
d = client.me.get()
setTimeout ->
  d.then(print)
, 2000
# client.app('foo').update(__dirname + '/basic.coffee', print)
