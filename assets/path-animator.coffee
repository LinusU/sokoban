
i = 0
S = 40

forPos = (obj, fn) ->
  fn obj.x + 1, obj.y + 0
  fn obj.x - 0, obj.y - 1
  fn obj.x - 1, obj.y - 0
  fn obj.x + 0, obj.y + 1

class PathAnimator
  constructor: (@obj) ->
    @id = 'path-animator-' + (i++)
    @cb = null
    @el = document.createElement 'style'
    @el.type = 'text/css'
    document.querySelector('head').appendChild @el
    @obj.el.addEventListener 'webkitAnimationEnd', =>
      @reset()
      @cb()
  destroy: ->
    document.querySelector('head').removeChild @el
  reset: ->
    @obj.el.style.webkitAnimation = ''
    @el.innerHTML = ''
  findPath: (sokoban, target) ->

    path = []
    next = []
    pathFrom = {}

    iterate = (obj) =>
      forPos obj, (x, y) =>
        if pathFrom[x + ',' + y] isnt undefined
          return
        if sokoban.isSolid(x, y)
          return
        pathFrom[x + ',' + y] = obj
        next.push { x: x, y: y }
      while next.length
        iterate next.shift()

    pathFrom[@obj.x + ',' + @obj.y] = null
    iterate { x: @obj.x, y: @obj.y }

    if pathFrom[target.x + ',' + target.y]

      iterate = (x, y) =>
        obj = pathFrom[x + ',' + y]
        if obj
          path.unshift obj
          iterate obj.x, obj.y

      path.unshift { x: target.x, y: target.y }
      iterate target.x, target.y

      return path

    else

      return false

  walk: (sokoban, target, @cb) ->

    path = @findPath sokoban, target
    rules = ['@-webkit-keyframes ' + @id + ' {']
    console.log path
    if path.length <= 1
      throw new Error 'Path is too short'

    path.forEach (p, i) ->
      rules.push '  ' + ((i / (path.length - 1)) * 100) + '% { -webkit-transform: translate(' + (p.x * S) + 'px, ' + (p.y * S) + 'px) }'

    rules.push '}'

    @el.innerHTML = rules.join '\n'

    time = switch path.length
      when 2 then 120
      when 3 then 200
      when 4 then 260
      when 5 then 300
      when 6 then 320
      else 340

    stop = path.pop()

    @obj.el.style.webkitAnimation = @id + ' ' + time + 'ms linear 0 1'
    @obj.el.style.webkitTransform = 'translate(' + (stop.x * S) + 'px, ' + (stop.y * S) + 'px)'

window.PathAnimator = PathAnimator
