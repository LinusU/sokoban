
assman = require 'assman'
express = require 'express'

assman.top __dirname

assman.register 'js', 'app', [ 'assets/path-animator.coffee', 'assets/sokoban.coffee', 'assets/app.coffee' ]
assman.register 'css', 'app', [ 'assets/sokoban.styl', 'assets/app.styl' ]
assman.register 'html', 'app', [ 'assets/app.jade' ]

assman.register 'svg', 'sprites', [ 'assets/sprites.svg' ]
assman.register 'jpg', 'background', [ 'assets/background.jpg' ]

app = express()

app.use assman.middleware

app.get '/', (req, res) ->
  res.redirect '/app.html'

app.listen 3400
