login_attempt_messages = [
  "That doesn't seem right. Care to try again?"
  "Hmmmm, still not right..."
  "Why don't you go look up that password and come back later."
]

exports.login = ->
  @_login_count ?= 0
  
  @prompt
    email: {prompt: 'Email'}
    password: {prompt: 'Password', hidden: true}
  .then (data) =>
    client = @client(data)
    client.me.get()
  .then (user) =>
    @login(user)
    
    @log('')
    @log "Welcome back! It's been way too long."
  .catch (err) =>
    if err.status_code is 401
      if ++@_login_count is 3
        @log('')
        @error login_attempt_messages[@_login_count - 1]
        return
        
      @log('')
      @error login_attempt_messages[@_login_count - 1]
      @log('')
      return exports.login.call(@)
    
    throw err

exports.logout = ->
  @logout()
  @log "We're really sad to see you go. =-("
