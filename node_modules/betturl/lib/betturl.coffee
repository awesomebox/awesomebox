STANDARD_PORT = {
  http: 80
  https: 443
}

type_parse = (value) ->
  return parseInt(value) if parseInt(value).toString() is value
  return parseFloat(value) if parseFloat(value).toString() is value
  return true if value.toLowerCase() is 'true'
  return false if value.toLowerCase() is 'false'
  return null if value.toLowerCase() is 'null'
  return undefined if value.toLowerCase() is 'undefined'
  value

parse_host = (host, protocol) ->
  [h, p] = host.split(':')
  p = if p? then parseInt(p) else STANDARD_PORT[protocol]
  {host: decodeURIComponent(h), port: p}

parse_query = (query) ->
  q = {}
  for kv in query.split('&')
    [k, v] = kv.split('=')
    q[decodeURIComponent(k)] = if v? then type_parse(decodeURIComponent(v)) else true
  q

exports.parse = (url, opts = {}) ->
  [_x, _x, protocol, _x, auth, host, path] = /^(([^:]*):\/\/)?(([^:]*:[^@]*)@)?([^\/]+)?(\/.*)?$/.exec(url)
  [_x, path, _x, query, _x, hash] = /(\/[^?#]*)?(\?([^#]+))?(#(.*))?/.exec(path)
  
  if host?
    hosts = host.split(',').map (h) -> parse_host(h, protocol)
  if auth?
    [user, password] = auth.split(':')
  
  if opts.parse_query is false
    query = if query? then decodeURIComponent(query) else ''
  else
    query = if query? then parse_query(query) else {}
  
  path ?= '/'
  
  o = {
    url: url
    path: decodeURIComponent(path)
    query: query
    hash: hash or ''
  }
  
  o.protocol = protocol if protocol?
  o.hosts = hosts if hosts?
  if hosts?.length is 1
    o.host = hosts[0].host
    o.port = hosts[0].port
  o.auth = {user: decodeURIComponent(user), password: decodeURIComponent(password)} if user? or password?
  
  o

exports.format = (parsed) ->
  host = parsed.host or parsed.hosts?[0]?.host or 'localhost'
  port = parsed.port or parsed.hosts?[0]?.port or STANDARD_PORT[parsed.protocol]
  port = if STANDARD_PORT[parsed.protocol] is port then '' else ':' + port
  
  auth = if parsed.auth?.user? and parsed.auth?.password? then encodeURIComponent(parsed.auth.user) + ':' + encodeURIComponent(parsed.auth.password) + '@' else ''
  
  path = '/' + parsed.path.replace(/^\/+/, '')
  query = []
  for k, v of parsed.query
    query.push(encodeURIComponent(k) + '=' + encodeURIComponent(v))
  query = query.join('&')
  query = '?' + query if query isnt ''
  hash = if parsed.hash is '' then '' else '#' + parsed.hash
  
  parsed.protocol + '://' + auth + host + port + path + query + hash
