class UnauthorizedError extends Error
  constructor: ->
    super()
    Error.captureStackTrace(@, arguments.callee)
    @name = 'UnauthorizedError'

exports.UnauthorizedError = UnauthorizedError
exports.unauthorized = -> new UnauthorizedError()

exports.is_unauthorized = (err) ->
  return true if err?.status_code is 401
  return true if err?.name is 'UnauthorizedError'
  false
