
instance = null

document.body.addEventListener 'touchmove', (e) ->
  e.preventDefault()

showScene = (scene) ->
  document.getElementById('menu').classList.add 'hide'
  document.getElementById('main').classList.add 'hide'
  document.getElementById('solved').classList.add 'hide'
  setTimeout ->
    document.getElementById(scene).classList.remove 'hide'

window.mainMenu = ->
  showScene 'menu'

window.newGame = ->
  showScene 'main'
  if instance then instance.destroy()
  instance = new Sokoban(document.getElementById('game'))

  # For debugging only
  window.instance = instance

window.undoMove = ->
  instance.undo()

window.showSolved = ->
  showScene 'solved'
