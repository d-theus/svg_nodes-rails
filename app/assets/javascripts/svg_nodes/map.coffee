# TODO:
# 
# handlers
window.SvgNodes = {}

class SvgNodes.Map
  constructor: (parent = null, params = {} )->
    @w = params.w
    @h = params.h
    @svg = Snap(parent) || Snap(@w, @h)

    @nodes = []
    @edges = []

    @options = params.options || {
      nodes: {
        fill: 'white',
        stroke: 'black',
        strokeWidth: 1.5,
        fillOpacity: 1
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

  addEdge: (edge)->
    src = this.fetchNode(edge.from)
    des = this.fetchNode(edge.to)

    e = new SvgNodes.Edge(
      this,
      src,
      des
    )
    @edges.push(e)

  fetchNode: (id)->
    @nodes.find (node)->
      node.id == id

class SvgNodes.Responsible
  constructor: ->
    @svg.click ->
      for fn in @_clickHandlers
        fn()
    @svg.drag ->
      for fn in @_dragHandlers
        fn()

  onClick: (fn)->
    @_clickHandlers.push(fn)

  onDrag:  (fn)->
    @_dragHandlers.push(fn)

class SvgNodes.Node extends SvgNodes.Responsible
  constructor: (@map, @id, @x, @y, @r, @text, @style)->
    @_clickHandlers = []
    @_dragHandlers =  []
    @svg = @map.svg.circle(@x, @y, @r)
    @label = new SvgNodes.Label(@map, @x + @r, @y + @r, @text)
    @svg.attr(@map.options.nodes)
    this.onClick ->
      alert "Fancy click"

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
