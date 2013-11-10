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
  canvas  = d3.select('#recruit-map').append('canvas')
    .attr('width', env.width)
    .attr('height', env.height)
  context = canvas.node().getContext '2d'
  path    = d3.geo.path().projection(env.projection).context(context)
  radius  = d3.scale.linear().domain([1, 2, 3, 4, 5]).range [0.1, 0.3, 0.5, 0.8, 2]

  scaleForRetina canvas, context

  # Draw US national outline and states outlines
  context.beginPath()
  path(env.nation)
  path(env.states)
  context.save()

  context.lineWidth = 1
  context.strokeStyle = "#333"
  context.stroke()

  context.shadowBlur = 6
  context.globalCompositeOperation = 'color-dodge'

  bygid = d3.nest()
    .key((d) -> d.gid)
    .rollup((d) -> d[0])
    .map(env.places)

  hotspots = d3.nest()
    .key((d) -> d.place_gid)
    .rollup((d) -> d.length)
    .entries(env.recruits)

  hotspots.sort (a, b) -> d3.descending(a.values, b.values)
  topPlaces = hotspots[0..10].map (spot) -> spot.place = bygid[spot.key]; spot

  for recruit in env.recruits
    coordinates = env.projection [recruit.lat, recruit.lon]
    context.beginPath()
    context.arc coordinates[0], coordinates[1], radius(recruit.stars), 0, Math.PI * 2, false
    context.fillStyle = env.colors[recruit.stars - 1]
    context.shadowColor = env.colors[recruit.stars - 1]
    context.fill()

  context.restore()
  context.shadowBlur = 0
  context.globalCompositeOperation = 'normal'
  context.fillStyle = 'fff'
  context.lineWidth = 0.5
  context.strokeStyle = "333"

  for city in topPlaces
    place = city.place
    coordinates = env.projection [place.lon, place.lat]
    context.beginPath()
    context.arc coordinates[0], coordinates[1], 3, 0, Math.PI * 2, false
    context.fillText("#{place.name}", coordinates[0] + 5, coordinates[1] + 5)
    context.strokeText("#{place.name}", coordinates[0] + 5, coordinates[1] + 5)
    context.fill()
    context.stroke()

$(document).on 'data.loaded', render
