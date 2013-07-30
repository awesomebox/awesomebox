View = require './view'

class Route
  @respond: (req, res, next) ->
    View.http_render(req, res, next)
  
  @respond_error: (err, req, res, next) ->
    return next(err) unless req.view.command.content_type is 'html'
    
    code = err.status if err.status?
    code = 500 if code < 400
    code ?= 500
    
    data =
      req: req
      res: res
      err: err
    
    View.render_file __dirname + '/templates/error', 'html', data, (err, content) ->
      return next(err) if err?
      View.send_response(res, code, 'html', content)
  
  @not_found: (req, res, next) ->
    return next() unless req.view.command.content_type is 'html'
    
    data =
      req: req
      res: res
    
    View.render_file __dirname + '/templates/404', 'html', data, (err, content) ->
      return next(err) if err?
      View.send_response(res, 404, 'html', content)

module.exports = Route
