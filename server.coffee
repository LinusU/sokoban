
assman = require 'assman'
express = require 'express'

assman.top __dirname

assman.register 'js', 'app', [ 'assets/levels.coffee', 'assets/path-animator.coffee', 'assets/sokoban.coffee', 'assets/app.coffee' ]
assman.register 'css', 'app', [ 'assets/sokoban.styl', 'assets/app.styl' ]
assman.register 'html', 'app', [ 'assets/app.jade' ]

assman.register 'svg', 'sprites', [ 'assets/sprites.svg' ]
assman.register 'svg', 'instructions', [ 'assets/instructions.svg' ]

assman.register 'jpg', 'background', [ 'assets/background.jpg' ]
assman.register 'png', 'touch-icon-144', [ 'assets/touch-icon-144.png' ]

app = express()

app.use assman.middleware

app.get '/', (req, res) ->
  res.redirect '/app.html'

cacheDate = do ->
  if (process.env.NODE_ENV || 'production') is 'development'
    -> Date.now()
  else
    date = Date.now()
    -> date

app.get '/cache.mf', (req, res) ->
  res.set 'Content-Type', 'text/cache-manifest'
  res.send 200, """
    CACHE MANIFEST
    # #{cacheDate()}

    CACHE:
    # App
    /app.js
    /app.css
    /app.html
    # SVG
    /sprites.svg
    /instructions.svg
    # Background
    /background.jpg

  """

app.listen 3400
