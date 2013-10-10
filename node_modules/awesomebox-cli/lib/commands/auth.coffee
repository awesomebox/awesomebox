login_attempt_messages = [
  "That doesn't seem right. Care to try again?"
  "Hmmmm, still not right..."
  "Why don't you go look up that password and come back later."
]

exports.login = (cb) ->
  @_login_count ?= 0
  
  @prompt.get
    properties:
      email:
        required: true
      password:
        required: true
        hidden: true
  , (err, data) =>
    return cb(err) if err?
    
    client = @client(data)
    client.me.get (err, user) =>
      if err? and err.status_code is 401
        if ++@_login_count is 3
          @log('')
          @error login_attempt_messages[@_login_count - 1]
          return cb()
          
        @log('')
        @error login_attempt_messages[@_login_count - 1]
        @log('')
        return process.nextTick => exports.login.call(@, cb)
      
      return cb(err) if err?
      
      @login(user)
      
      @log('')
      @log "Welcome back! It's been way too long."
      
      cb()

exports.logout = (cb) ->
  @logout()
  @log "We're really sad to see you go. =-("
  cb()
