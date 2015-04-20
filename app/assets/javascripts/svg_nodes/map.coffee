window.SvgNodes = {}
class SvgNodes.Map
  constructor: (parent = null, params = {} )->
    @w = params.w
    @h = params.h
    @svg = Snap(parent) || Snap(@w, @h)

    @nodes = []
    @edges = []

    @css = {}

  render: ()->
    @nodes.forEach(((node)->
      node.draw(@svg)).bind(this))

  addNode: (node)->
    node = new Node(node) unless node.draw
    @nodes.push(node)
    this.render()

