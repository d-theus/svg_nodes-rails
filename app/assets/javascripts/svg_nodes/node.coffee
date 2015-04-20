class SvgNodes.Node
  constructor: (x, y, r, label, css)->
    @x = x
    @y = y
    @r = r
    @label = label || 'noname'
    @css = css

  draw: (svg)->
    svg.circle(@x, @y, @r)
    svg.text(@x + @r, @y + @r, @label)
