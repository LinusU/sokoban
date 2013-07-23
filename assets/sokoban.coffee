
S = 40

forPos = (obj, fn) ->
  forDelta (dx, dy) ->
    fn obj.x + dx, obj.y + dy, dx, dy

forDelta = (fn) ->
  fn 1, 0
  fn 0, -1
  fn -1, 0
  fn 0, 1

class Block
  constructor: (@parent, @type, @x, @y) ->
    @el = document.createElement 'div'
    @el.className = 'block block-' + @type
    @el.style.webkitTransform = 'translate(' + (@x * S) + 'px, ' + (@y * S) + 'px)'
    @parent.board.appendChild @el
    @anim = (if @canMove() then new PathAnimator @ else null)
  moveTo: (x, y, cb) ->
    @anim.walk @parent, { x: x, y: y }, ->
      if cb then do cb
    @x = x
    @y = y
  canMove: ->
    @type in ['box', 'player']
  isSolid: ->
    @type in ['box', 'wall', 'player']
  destroy: ->
    if @anim then @anim.destroy()

class Sokoban
  constructor: (@el) ->
    @el.classList.add 'sokoban'
    @map = null
    @board = null
  reloadMap: ->
    @loadMap @currentSetId, @currentMapId
  nextMap: ->
    if window.fetchLevel @currentSetId, @currentMapId + 1
      @loadMap @currentSetId, @currentMapId + 1
    else
      window.showSolved()
  loadMap: (set, id) ->
    @currentSetId = set
    @currentMapId = id
    @destroy()
    @board = document.createElement 'div'
    @board.className = 'board'
    @el.appendChild @board
    @boxes = []
    @touch = []
    @undos = []
    @mode = 'wait'
    @map = window.fetchLevel(@currentSetId, id).split('\n').map (row, y) =>
      row.split('').map (cell, x) =>
        switch cell
          when ' '
            []
          when '#'
            [ new Block @, 'wall', x, y ]
          when '$'
            box = new Block @, 'box', x, y
            @boxes.push box
            [ box ]
          when '.'
            [ new Block @, 'goal', x, y ]
          when '*'
            box = new Block @, 'box', x, y
            box.el.classList.add 'in-goal'
            @boxes.push box
            [
              new Block @, 'goal', x, y
              box
            ]
          when '@'
            @player = new Block @, 'player', x, y
            [ @player ]
          when '+'
            goal = new Block @, 'goal', x, y
            @player = new Block @, 'player', x, y
            [ goal, @player ]
          else
            throw new Error 'Unknown block type'

    @fillFloor()

    w = (@map.reduce ((p, c) -> Math.max(p, c.length)), 0) * S
    h = @map.length * S

    @board.style.width = w + 'px'
    @board.style.height = h + 'px'
    @board.style.marginTop = -(h/2) + 'px'
    @board.style.marginLeft = -(w/2) + 'px'
    @setMode 'select'

  destroy: ->
    if @map
      @map.forEach (e) -> e.forEach (e) -> e.forEach (e) -> e.destroy()
      @map = null
    if @board
      @el.removeChild @board
      @board = null
  undo: ->
    if @undos.length and @mode isnt 'wait'
      val = @undos.pop()
      @setMode 'wait'
      @moveTo @player, val.player.x, val.player.y
      @moveTo val.block.instance, val.block.x, val.block.y, =>
        @setMode 'select'
  get: (x, y) ->
    try
      @map[y][x]
    catch e
      []
  fillFloor: ->

    iterate = (x, y) =>
      pos = @get(x, y)
      if (pos.length is 0 or pos[0].type not in ['wall', 'floor'])
        @map[y][x].unshift new Block @, 'floor', x, y
        forPos { x: x, y: y }, iterate

    iterate @player.x, @player.y

  isFinished: ->
    @el.querySelector('.block-box:not(.in-goal)') is null
  isSolid: (x, y) ->
    blocks = @get x, y
    for b in blocks
      if b.isSolid()
        return true
    return false
  moveTo: (obj, x, y, cb) ->

    pos = @map[obj.y][obj.x]
    pos.splice(pos.indexOf(obj))

    obj.moveTo x, y, cb

    pos = @map[y][x]
    pos.push obj

    if obj.type is 'box'
      if pos[1].type is 'goal'
        obj.el.classList.add 'in-goal'
      else
        obj.el.classList.remove 'in-goal'

  handleTouch: (e) ->

    switch e.action
      when 'mode'
        @setMode e.value
      when 'select'
        @target = e.value
        @setMode 'push'
      when 'push'
        doThePush = =>
          @undos.push {
            player: { x: @player.x, y: @player.y }
            block: { instance: @target, x: @target.x, y: @target.y }
          }
          @moveTo @target, e.x, e.y
          @moveTo @player, e.x + e.dx, e.y + e.dy, =>
            if @isFinished()
              @nextMap()
            else
              @setMode 'select'
        @setMode 'wait'
        if @player.x is (@target.x + e.dx) and @player.y is (@target.y + e.dy)
          doThePush()
        else
          @moveTo @player, @target.x + e.dx, @target.y + e.dy, doThePush
      when 'walk'
        @setMode 'wait'
        @moveTo @player, e.x, e.y, =>
          @setMode 'select'

  setMode: (@mode) ->

    @touch.map (e) => @board.removeChild e
    @touch = @possibles().map (e) =>

      el = document.createElement 'div'
      el.className = 'touch'
      el.style.webkitTransform = 'translate(' + (e.x * S) + 'px, ' + (e.y * S) + 'px)'
      el.addEventListener 'touchstart', => @handleTouch e

      @board.appendChild el
      return el

  reachables: ->

    ret = {}

    iterate = (obj) =>
      forPos obj, (x, y) =>
        if ret[x + ',' + y]
          return
        if @isSolid(x, y)
          return
        ret[x + ',' + y] = true
        iterate { x: x, y: y }

    ret[@player.x + ',' + @player.y] = true
    iterate { x: @player.x, y: @player.y }
    return ret

  possibles: ->
    switch @mode

      when 'wait'
        return []

      when 'walk'

        ret = []
        reachables = @reachables()

        for key of reachables
          [x, y] = key.split ','
          ret.push { x: parseInt(x), y: parseInt(y), action: 'walk' }

        ret.push {
          x: @player.x
          y: @player.y
          action: 'mode'
          value: 'select'
        }

        return ret

      when 'select'

        ret = {}
        reachables = @reachables()

        for b in @boxes
          forPos b, (x, y, dx, dy) =>
            if @isSolid(x, y) is false or (@player.x is x and @player.y is y)
              if @isSolid(b.x - dx, b.y - dy) is false or (@player.x is (b.x - dx) and @player.y is (b.y - dy))
                if reachables[x + ',' + y] isnt undefined
                  ret[b.x + ',' + b.y] =
                    x: b.x
                    y: b.y
                    action: 'select'
                    value: b

        ret[@player.x + ',' + @player.y] =
          x: @player.x
          y: @player.y
          action: 'mode'
          value: 'walk'

        return (ret[key] for key of ret)

      when 'push'

        ret = []
        reachables = @reachables()

        ret.push {
          x: @target.x
          y: @target.y
          action: 'mode'
          value: 'select'
        }

        forDelta (dx, dy) =>

          x = @target.x
          y = @target.y

          if reachables[(x + dx) + ',' + (y + dy)] isnt undefined
            iterate = =>
              x -= dx
              y -= dy
              if @isSolid(x, y) is false or (@player.x is x and @player.y is y)
                ret.push {
                  x: x
                  y: y
                  action: 'push'
                  value: @target
                  dx: dx
                  dy: dy
                }
                iterate()

            iterate()

        return ret

      else
        throw new Error 'Unknown mode:', @mode

window.Sokoban = Sokoban
