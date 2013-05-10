_ = require 'underscore'
walkabout = require 'walkabout'

handler = (err, req, res, next) ->
  return next(err) unless req.awesomebox.view_opts.view_type is 'html'
  
  res.statusCode = err.status if err.status?
  res.statusCode = 500 if res.statusCode < 400
  
  view = new awesomebox.View(
    file: walkabout(__dirname).join('error_handler.html.ejs')
    type: 'html'
    route: req.awesomebox.route
    view_data:
      req: req
      res: res
      err: err
  )
  view.render (err, data) ->
    res.set('Content-Type': 'text/html')
    res.send(data)

module.exports = (context, done) ->
  context.on 'post:server.configure', (server, args, results, next) ->
    server.http.use(handler)
    next()
  
  done()
