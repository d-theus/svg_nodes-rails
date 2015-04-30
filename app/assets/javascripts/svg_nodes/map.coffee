window.SvgNodes = {}

class SvgNodes.Map
  
  this._eventNameToHandlerName = (en) ->
    en.replace ':', '_'
  constructor: (parent = null, params = {} )->
    @w = params.w
    @h = params.h
    @svg = Snap(parent) || Snap(@w, @h)
    @domElement = @svg.node
    @bbox = {
      x: @svg.node.getBoundingClientRect().x
      y: @svg.node.getBoundingClientRect().y
    }


    @nodes = []
    @edges = []
    @selection = []

    @handlers =
      "selection:change": []
      "selection:empty": []
      "click:map": []
      "click:node": []
      "drag:map:start": []
      "drag:map:move": []
      "drag:map:end": []
      "drag:node:start": []
      "drag:node:move": []
      "drag:node:end": []
      "zoom": []

    @options = params.options ||
      nodes:
        fill: 'white',
        stroke: 'black',
        strokeWidth: 1.5,
        fillOpacity: 1,
        draggable: true
      edges:
        stroke: 'black',
        strokeWidth: 1
    @interactive = true
    @transformations =
      zoom: 1
      x:    0
      y:    0
      dx:   0
      dy:   0

    this._setDefaultHandlers()
    this.enableInteractivity()

  addNode: (node)->
    n = new SvgNodes.Node(
      this,
      node.id,
      node.x,
      node.y,
      node.r,
      node.label
    )
    @nodes.push(n)
    n

  addEdge: (edge)->
    src = this.fetchNode(edge.from)
    des = this.fetchNode(edge.to)

    e = new SvgNodes.Edge(
      this,
      src,
      des
    )
    @edges.push(e)
    e

  addEventListener: (eventName, handler) =>
    throw Error "Unexpected event type #{eventName}" unless @handlers[eventName]?
    @handlers[eventName].push(handler)

  fetchNode: (id)->
    @nodes.find (node)->
      node.id == id

  clear: =>
    @nodes.splice(0,@nodes.length)
    @edges.splice(0,@edges.length)
    @svg.clear()

  select: (entity, multi = false)=>
    this.deselectAll() unless multi
    @selection.push(entity) if entity? and not (entity in @selection)
    entity.highlight()

  deselect: (entity)=>
    i = @selection.indexOf(entity)
    @selection.splice(i,1) if i >= 0
    entity.dim()

  deselectAll: ()=>
    n.dim() for n in @selection
    @selection.splice(0, @selection.length)

  getSelectedIds: ()->
    (node.id for node in @selection when node.id?)

  getSelectedNodes: ()->
    (node for node in @selection when node.id?)

  _applyTransformations: =>
    m = @svg.transform().globalMatrix
    m.translate(
      @transformations.x + @transformations.dx,
      @transformations.y + @transformations.dy)
    m.scale(@transformations.zoom)
    @svg.transform(m)

  _freeze: ()=>
    @interactive = false
    setTimeout =>
      @interactive = true
    , 500

  ###
  # EVENTS
  ###
  
  ###
  # TODO:
  # Modify to use tag number id
  # rather than textual
  ###
  enableInteractivity: ()=>
    map = this
    @svg.click (e)->
      key = switch e.target.tagName
        when 'svg' then 'click:map'
        when 'circle' then 'click:node'
      fn(e) for fn in map.handlers[key]
    @svg.drag (dx, dy, x, y, e) ->
      key = switch e.target.tagName
        when 'svg' then 'drag:map:move'
        when 'circle' then 'drag:node:move'
      fn(dx, dy, x, y, e) for fn in map.handlers[key]
    ,         (x, y, e) ->
      key = switch e.target.tagName
        when 'svg' then 'drag:map:start'
        when 'circle' then 'drag:node:start'
      fn(x, y, e) for fn in map.handlers[key]
    ,         (e) ->
      key = switch e.target.tagName
        when 'svg' then 'drag:map:end'
        when 'circle' then 'drag:node:end'
      fn(e) for fn in map.handlers[key]
    @svg.node.addEventListener 'wheel', (e)->
      fn(e) for fn in map.handlers['zoom']


  _setDefaultHandlers: () =>
    @handlers['click:map'].push(this._onMapClick)
    @handlers['click:node'].push(this._onNodeClick)
    @handlers['drag:map:move'].push(this._onMapDrag)
    @handlers['drag:map:start'].push(this._onMapDragStart)
    @handlers['drag:map:end'].push(this._onMapDragEnd)
    @handlers['drag:node:move'].push(this._onNodeDrag)
    @handlers['drag:node:start'].push(this._onNodeDragStart)
    @handlers['drag:node:end'].push(this._onNodeDragEnd)
    @handlers['zoom'].push(this._onScroll)
  ###
  # HANDLERS
  ###
  # FIXME:
  # fix drag -> click behavior
  #
  
  _onMapClick: (e) =>
    e.stopPropagation()
    return unless @interactive
    this.deselectAll() unless e.ctrlKey
  _onNodeClick: (e) =>
    e.stopPropagation()
    return unless @interactive
    node = this.fetchNode(e.target.node_id)
    if e.target.node_id in this.getSelectedIds()
      this.deselect(node)
    else
      this.select(node, e.ctrlKey)
    this._freeze()
  _onNodeDragStart: (x, y, e) =>
    node = this.fetchNode(e.target.node_id)
    this.select(node)
  _onNodeDrag: (dx, dy, x, y, e) =>
    @selection[0].move(x+dx, y+dy)
  _onNodeDragEnd: (e) =>
    this._freeze()
  _onMapDrag: (dx, dy, x, y, e) =>
    e.stopPropagation()
    return unless dx*dy > 0
    @transformations.dx = dx
    @transformations.dy = dy
    this._applyTransformations()
    this._freeze()
  _onMapDragStart: (x, y, e) =>
    e.stopPropagation()
  _onMapDragEnd: (e) =>
    e.stopPropagation()
    @transformations.x = @transformations.dx
    @transformations.y = @transformations.dy
    @transformations.dx = 0
    @transformations.dy = 0
    this._freeze()
  _onScroll: (e) =>
    factor = e.deltaY * 0.05
    @transformations.zoom += factor
    this._applyTransformations()




class SvgNodes.Node
  constructor: (@map, @id, @x, @y, @r, @text, @style)->
    @_clickHandlers = []
    @_dragHandlers =  []
    @svg = @map.svg.circle(@x, @y, @r)
    @svg.node.node_id = @id
    @label = new SvgNodes.Label(@map, @x + @r, @y + @r, @text)
    @svg.attr(@map.options.nodes)
    #this.setDraggable() if @map.options.nodes.draggable
    #this.setSelectable()

  #setDraggable: () =>
    #@svg.drag (dx, dy, x, y, e)=>
      #x = x - @map.bbox.x
      #y = y - @map.bbox.y
      #this.move(x,y)
      #@map.interactive = false

  #setSelectable: =>
    #@svg.click (e)=>
      #if not @highlighted then this.highlight() else this.dim()
      #@map.select(this)
      #e.stopPropagation()

  move: (x, y)=>
    @x = x
    @y = y
    this.attr
      cx: @x
      cy: @y
    this._moveEdges()
    this._moveLabel()

  highlight: =>
    @highlighted = true
    @svg.transform(Snap.matrix().scale(1.1, 1.1, @x, @y))
    @label.attr(fontWeight: 'bold')

  dim: =>
    @highlighted = false
    @svg.transform(Snap.matrix())
    @label.attr(fontWeight: 'normal')

  _moveEdges: =>
    @map.edges.forEach (e)=>
      if e.src.id == @id
        e.svg.attr
          x1: @x
          y1: @y
      if e.dest.id == @id
        e.svg.attr
          x2: @x
          y2: @y
  _moveLabel: =>
    @label.svg.attr
      x: @x + @r
      y: @y + @r

  attr: (hash)->
    @svg.attr(hash)

class SvgNodes.Label
  constructor: (@map, @x, @y, @text, @style)->
    @_clickHandlers = []
    @_dblClickHandlers = []
    @_dragHandlers =  []
    @svg = @map.svg.text(@x, @y, @text)
  attr: (hash)->
    @svg.attr(hash)

class SvgNodes.Edge
  constructor: (@map, @src, @dest)->
    @_clickHandlers = []
    @_dragHandlers =  []
    earlier = if @src.id < @dest.id
      @src
    else
      @dest
    @svg = @map.svg.line(@src.x, @src.y, @dest.x, @dest.y)
    @svg.insertBefore(earlier.svg)
    @svg.attr(@map.options.edges)
  attr: (hash)->
    @svg.attr(hash)
