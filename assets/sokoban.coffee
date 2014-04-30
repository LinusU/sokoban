
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
  isSolid: ->
    @type in ['box', 'wall', 'player']

class Sokoban
  constructor: (@el) ->
    @el.classList.add 'sokoban'
    @map = null
    @anim = null
    @board = null
  reloadMap: ->
    @loadMap @currentSetId, @currentMapId
  nextMap: ->
    if window.fetchLevel @currentSetId, @currentMapId + 1
      @loadMap @currentSetId, @currentMapId + 1
    else
      window.showSolved()
  deflate: ->
    deflateCell = (e) ->
      switch e.length
        when 0 then return ' '
        when 1
          switch e[0].type
            when 'floor' then return ' '
            when 'wall' then return '#'
        when 2
          switch e[1].type
            when 'box' then return '$'
            when 'goal' then return '.'
            when 'player' then return '@'
        when 3
          if e[1].type is 'goal' and e[2].type is 'player' then return '+'
          if e[1].type is 'goal' and e[2].type is 'box' then return '*'
      throw new Error 'Unknown cell: ' + JSON.stringify e
    data = @map.map((e) -> e.map(deflateCell).join('')).join '\n'
    # FIXME: undos
    return { data: data, moves: @moves, setId: @currentSetId, mapId: @currentMapId } # , undos: @undos
  inflate: (obj) ->
    @loadData obj.data
    @moves = obj.moves
    @currentSetId = obj.setId
    @currentMapId = obj.mapId
    # FIXME: undos
    # @undos = obj.undos
  loadMap: (@currentSetId, @currentMapId) ->
    @loadData window.fetchLevel @currentSetId, @currentMapId
  loadData: (data) ->
    @destroy()
    @board = document.createElement 'div'
    @board.className = 'board'
    @el.appendChild @board
    @moves = 0
    @boxes = []
    @touch = []
    @undos = []
    @mode = 'wait'
    @map = data.split('\n').map (row, y) =>
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
            @anim = new PathAnimator @player
            [ @player ]
          when '+'
            goal = new Block @, 'goal', x, y
            @player = new Block @, 'player', x, y
            @anim = new PathAnimator @player
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
    @map = null
    if @board
      @el.removeChild @board
      @board = null
  undo: ->
    if @undos.length and @mode isnt 'wait'
      val = @undos.pop()
      @setMode 'wait'
      @moves = val.moves
      doThePush = =>
        push =
          box: val.block.instance
          x: val.block.x
          y: val.block.y
        @moveTo @player, val.player.x, val.player.y, push, =>
          @setMode 'select'
      if @player.x is val.player.tx and @player.y is val.player.ty
        doThePush()
      else
        @moveTo @player, val.player.tx, val.player.ty, null, doThePush
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
    @get(x, y).reduce ((p, c) -> p || c.isSolid()), false
  hasType: (x, y, type) ->
    @get(x, y).reduce ((p, c) -> p || (c.type is type)), false
  moveTo: (obj, x, y, push, cb) ->

    if push
      push.orig = { x: push.box.x, y: push.box.y }
      @moveTo push.box, push.x, push.y, null, null

    pos = @map[obj.y][obj.x]
    pos.splice pos.indexOf(obj), 1

    if obj.type is 'player'
      @anim.walk @, { x: x, y: y }, push, cb

    obj.x = x
    obj.y = y

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
            player: { x: @player.x, y: @player.y, tx: e.x + e.dx, ty: e.y + e.dy }
            block: { instance: @target, x: @target.x, y: @target.y }
            moves: @moves
          }
          @moves += Math.abs (@target.x - e.x) + (@target.y - e.y)
          push =
            box: @target
            x: e.x
            y: e.y
          @moveTo @player, e.x + e.dx, e.y + e.dy, push, =>
            if @isFinished()
              window.markLevelCompleted @currentSetId, @currentMapId
              window.showStats @moves
            else
              window.saveCurrentGame()
              @setMode 'select'
        @setMode 'wait'
        if @player.x is (@target.x + e.dx) and @player.y is (@target.y + e.dy)
          doThePush()
        else
          @moveTo @player, @target.x + e.dx, @target.y + e.dy, null, doThePush
      when 'walk'
        @setMode 'wait'
        @moveTo @player, e.x, e.y, null, =>
          window.saveCurrentGame()
          @setMode 'select'

  setMode: (@mode) ->

    @touch.map (e) => @board.removeChild e
    @touch = @possibles().map (e) =>

      el = document.createElement 'div'
      el.className = 'touch'
      el.style.webkitTransform = 'translate(' + (e.x * S) + 'px, ' + (e.y * S) + 'px)'
      el.addEventListener (if hasTouchSupport then 'touchstart' else 'click'), => @handleTouch e

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

  findPossiblePushesInGoal: (x, y, px, py) ->

    ret = []
    next = [[x, y]]
    done = {}



    iterate = (x, y) ->
      forDelta (dx, dy) ->
        xx = x + dx
        yy = y + dy

    iterate x, y

    return ret


window.Sokoban = Sokoban
