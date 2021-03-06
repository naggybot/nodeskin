collection = Skin.db.collection('users')
skin = save: collection.save

emailRegExp = /^([a-zA-Z0-9_\-\.]+)@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.)|(([a-zA-Z0-9\-]+\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})(\]?)$/

Skin.db.bind('users').bind({
  save: (user, done) ->
    self = this
    user.createdAt ||= new Date()
    user.updatedAt = new Date()
    Skin.db.keywords.fromText [
      user.username
      user.email
    ].join(" "), (err, keywords) ->
      user.keywords = keywords
      skin.save.call self, user, strict: true , done
  
  hashPassword: (password, done) ->
    return done(null, null) if !password || password.length == 0
    bcrypt.genSalt 10, (err, salt) ->
      bcrypt.hash password.toString(), salt, done

  validate: (user, done) ->
    async.parallel {
      username: (next) ->
        if !user.username || user.username.isBlank()
          return next(null, "Username is required")
        next()
      email: (next) -> Skin.db.users.validateEmail(user, next)
      password: (next) -> Skin.db.users.validatePassword(user, next)
    }, (err, results) ->
      return done(err) if err
      keys = Object.keys(results).findAll (key) -> !!results[key]
      done(null, Object.select(results, keys))

  validateEmail: (user, done) ->
    if !user.email || user.email.isBlank()
      return done(null, "Email is required")
    if !user.email.match(emailRegExp)
      return done(null, "Email '#{user.email}' doesn't look like email. Please check if you have a missprint.")
    done()

  validatePassword: (user, done) ->
    if !user.password || user.password.isBlank()
      return done(null, "Password is required")
    if 'confirmationPassword' of user
      if !user.confirmationPassword
        return done(null, 'Please confirm your password')
      if user.confirmationPassword != user.password
        return done(null, 'Password confirmation should match the password')
    done()

  autocomplete: (text, done) ->
    Skin.db.keywords.toConditions text, (err, conditions) ->
      return done(err) if err
      return done(null, [])  unless conditions
      Skin.db.users.find(conditions).limit(10).toArray done
})

