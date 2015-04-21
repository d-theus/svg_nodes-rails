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
    c = @svg.circle(
      node.x,
      node.y,
      node.r
    )
    t = @svg.text(
      node.x + 2 * node.r,
      node.y,
      node.label
    )
    c.attr(@options.nodes)
    node.element = @svg.g(c, t)
    @nodes.push(node)

  addEdge: (edge)->
    src = this.fetchNode(edge.from)
    des = this.fetchNode(edge.to)
    earlierNode = if edge.from.id > edge.to.id
      des.element
    else
      src.element

    l = @svg.line(
      src.x,
      src.y,
      des.x,
      des.y
    )
    l.insertBefore(earlierNode)
    l.attr(@options.edges)
    @edges.push(edge)

  fetchNode: (id)->
    @nodes.find (node)->
      node.id == id

  _default_onclick: ()->
    alert 'Clicked'
