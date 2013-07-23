
window.hasTouchSupport = ('ontouchmove' in document)

instance = new Sokoban(document.getElementById('game'))

# For debugging only
window.instance = instance

if hasTouchSupport
  document.body.addEventListener 'touchmove', (e) ->
    e.preventDefault()
else
  for e in document.querySelectorAll('[ontouchstart]')
    e.setAttribute 'onclick', e.getAttribute 'ontouchstart'

window.addEventListener 'load', ->
  window.applicationCache.addEventListener 'updateready', ->
    if window.applicationCache.status is window.applicationCache.UPDATEREADY
      window.applicationCache.swapCache()
      document.querySelector('.btn.update').classList.remove 'hide'

showScene = (scene) ->
  document.getElementById('menu').classList.add 'hide'
  document.getElementById('main').classList.add 'hide'
  document.getElementById('stats').classList.add 'hide'
  document.getElementById('levels').classList.add 'hide'
  document.getElementById('solved').classList.add 'hide'
  setTimeout ->
    document.getElementById(scene).classList.remove 'hide'

window.mainMenu = ->
  showScene 'menu'

window.newGame = (set, lvl) ->
  showScene 'main'
  instance.loadMap set, lvl

window.undoMove = ->
  instance.undo()

window.resetLevel = ->
  instance.reloadMap()

window.showSolved = ->
  showScene 'solved'

window.showStats = (moves) ->
  el = document.getElementById 'stats'
  el.classList.remove 'hide'
  el.querySelector('p').innerText = moves + ' pushes'

window.nextLevel = ->
  el = document.getElementById 'stats'
  el.classList.add 'hide'
  instance.nextMap()

window.showLevels = (set) ->

  document.getElementById('levels-list').innerHTML = ''

  showScene 'levels'

  size = 8
  list = window.fetchLevelSet set

  images = list.map (e) ->
    rows = e.split '\n'
    canvas = document.createElement 'canvas'
    w = rows.reduce ((p, c) -> Math.max(p, c.length)), 0
    h = rows.length
    canvas.width = 20 * size
    canvas.height = 16 * size
    ctx = canvas.getContext '2d'
    ctx.scale size, size
    ctx.translate (20 - w) / 2, (16 - h) / 2
    rows.forEach (row, y) ->
      for char, x in row
        switch char
          when ' ' then ctx.fillStyle = 'transparent'
          when '#' then ctx.fillStyle = 'black'
          when '$' then ctx.fillStyle = 'green'
          when '*' then ctx.fillStyle = 'green'
          when '@' then ctx.fillStyle = 'blue'
          when '+' then ctx.fillStyle = 'blue'
          when '.' then ctx.fillStyle = 'yellow'
        ctx.fillRect x, y, 1, 1
    canvas

  images.forEach (e, lvl) ->
    e.addEventListener (if hasTouchSupport then 'touchstart' else 'click'), -> window.newGame set, lvl
    document.getElementById('levels-list').appendChild e


