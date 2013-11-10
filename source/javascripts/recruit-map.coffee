# Scale canvas elements to support retina if a retina display is detected.
#
# canvas - The canvas element
# context - The canvas context
#
# Returns nothing
scaleForRetina = (canvas, context) ->
  rwidth = $(canvas.node()).width()
  rheight = $(canvas.node()).width()

  devicePixelRatio = window.devicePixelRatio || 1
  backingStoreRatio = context.webkitBackingStorePixelRatio ||
                      context.mozBackingStorePixelRatio ||
                      context.msBackingStorePixelRatio ||
                      context.oBackingStorePixelRatio ||
                      context.backingStorePixelRatio || 1

  ratio = devicePixelRatio / backingStoreRatio

  if window.devicePixelRatio != backingStoreRatio
    canvas
      .attr('width', rwidth * ratio)
      .attr('height', rheight * ratio)
      .style('width', rwidth + 'px')
      .style('height', rheight + 'px')

    context.scale ratio, ratio

# The main entry point for rendering the map to the screen
#
# event - the `data.loaded` event object
# env - The environment containing all data and previously computed
#       projections
#
# Returns nothing
render = (event, env) ->
  canvas = d3.select('#recruit-map').append('canvas')
    .attr('width', env.width)
    .attr('height', env.height)
  context = canvas.node().getContext '2d'
  env.path.context(context)

  scaleForRetina canvas, context

  context.beginPath()
  env.path(env.nation)
  env.path(env.states)
  context.lineWidth = 1
  context.strokeStyle = "#333"
  context.stroke()



$(document).on 'data.loaded', render
