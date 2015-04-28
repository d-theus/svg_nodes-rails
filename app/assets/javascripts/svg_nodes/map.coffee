# TODO:
# 
# handlers
window.SvgNodes = {}

class SvgNodes.Map
  constructor: (parent = null, params = {} )->
    @w = params.w
    @h = params.h
    @svg = Snap(parent) || Snap(@w, @h)
    @bbox = {
      x: @svg.node.getBoundingClientRect().x
      y: @svg.node.getBoundingClientRect().y
    }


    @nodes = []
    @edges = []

    @options = params.options || {
      nodes: {
        fill: 'white',
        stroke: 'black',
        strokeWidth: 1.5,
        fillOpacity: 1,
        draggable: true
      },
      edges: {
        stroke: 'black',
        strokeWidth: 1
      }
    }

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

  fetchNode: (id)->
    @nodes.find (node)->
      node.id == id

  clear: =>
    @nodes.splice(0,@nodes.length)
    @edges.splice(0,@edges.length)
    @svg.clear()

class SvgNodes.Responsible
  constructor: ->
  onClick: (fn, bubbling = true)=>
    @_clickHandlers.push(fn)
    self = this
    @svg.click (e)->
      fn() for fn in self._clickHandlers
      e.stopPropagation() unless bubbling

  onDrag:  (fn, bubbling = true)=>
    @_dragHandlers.push(fn)
    self = this
    @svg.drag (e)->
      fn() for fn in self._dragHandlers
      e.stopPropagation() unless bubbling

class SvgNodes.Node extends SvgNodes.Responsible
  constructor: (@map, @id, @x, @y, @r, @text, @style)->
    @_clickHandlers = []
    @_dragHandlers =  []
    @svg = @map.svg.circle(@x, @y, @r)
    @label = new SvgNodes.Label(@map, @x + @r, @y + @r, @text)
    @svg.attr(@map.options.nodes)
    this.setDraggable(@map) if @map.options.nodes.draggable

  setDraggable: (map, draggable = true) =>
    return unless draggable
    node = this
    this.svg.drag (dx, dy, x, y, e)=>
      x = x - map.bbox.x
      y = y - map.bbox.y
      this.move(x,y)

  move: (x, y)=>
    @x = x
    @y = y
    this.attr
      cx: @x
      cy: @y
    this._moveEdges()
    this._moveLabel()

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

class SvgNodes.Label extends SvgNodes.Responsible
  constructor: (@map, @x, @y, @text, @style)->
    @_clickHandlers = []
    @_dragHandlers =  []
    @svg = @map.svg.text(@x, @y, @text)
  attr: (hash)->
    @svg.attr(hash)

class SvgNodes.Edge extends SvgNodes.Responsible
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
