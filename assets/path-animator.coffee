
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
    if @box
      @box.el.style.webkitAnimation = ''
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
        if x is target.x and y is target.y
          next = { length: 0, push: (-> ) }
        else
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

  walk: (sokoban, target, push, @cb) ->

    rules = ['@-webkit-keyframes ' + @id + ' {']

    if push
      delta = Math.abs (target.x - @obj.x) + (target.y - @obj.y)
      dx = (target.x - @obj.x) / delta
      dy = (target.y - @obj.y) / delta
      path = [0..delta].map (i) => { x: @obj.x + dx * i, y: @obj.y + dy * i }
    else
      path = @findPath sokoban, target

    if path.length <= 1
      throw new Error 'Path is too short'

    path.forEach (p, i) ->
      rules.push '  ' + ((i / (path.length - 1)) * 100) + '% { -webkit-transform: translate(' + (p.x * S) + 'px, ' + (p.y * S) + 'px) }'

    rules.push '}'

    if push
      @box = push.box
      dx = @box.x - @obj.x
      dy = @box.y - @obj.y
      rules.push '@-webkit-keyframes ' + @id + '-box {'
      rules.push '0% { -webkit-transform: translate(' + (push.orig.x * S) + 'px, ' + (push.orig.y * S) + 'px) }'
      rules.push '100% { -webkit-transform: translate(' + (push.x * S) + 'px, ' + (push.y * S) + 'px) }'
      rules.push '}'

    @el.innerHTML = rules.join '\n'

    time = switch path.length
      when 2 then 120
      when 3 then 200
      when 4 then 260
      when 5 then 300
      when 6 then 320
      else 340

    @obj.el.style.webkitAnimation = @id + ' ' + time + 'ms linear 0 1'
    @obj.el.style.webkitTransform = 'translate(' + (target.x * S) + 'px, ' + (target.y * S) + 'px)'

    if push
      @box.el.style.webkitAnimation = @id + '-box ' + time + 'ms linear 0 1'
      @box.el.style.webkitTransform = 'translate(' + (push.x * S) + 'px, ' + (push.y * S) + 'px)'

    return (path.length - 1)

window.PathAnimator = PathAnimator
