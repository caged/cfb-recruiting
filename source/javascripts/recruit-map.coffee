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

  bygid = d3.nest()
    .key((d) -> d.gid)
    .rollup((d) -> d[0])
    .map(env.places)

  hotspots = d3.nest()
    .key((d) -> d.place_gid)
    .rollup((d) -> d.length)
    .entries(env.recruits)

  hotspots.sort (a, b) -> d3.descending(a.values, b.values)
  topPlaces = hotspots[0..14].map (spot) -> spot.place = bygid[spot.key]; spot

  for recruit in env.recruits
    coordinates = env.projection [recruit.lon, recruit.lat]
    context.beginPath()
    context.arc coordinates[0], coordinates[1], radius(recruit.stars), 0, Math.PI * 2, false
    context.fillStyle = 'rgba(255, 255, 255, 0.3)' #'rgba(223, 0, 83, 0.9)' #env.colors[recruit.stars - 1]
    context.shadowColor = 'rgba(255, 255, 255, 0.5)'
    context.fill()

  context.restore()
  context.shadowBlur = 0
  context.globalCompositeOperation = 'normal'
  context.fillStyle = 'fff'
  context.lineWidth = 0.5
  context.strokeStyle = "333"
  context.font = "12px Helvetica Neue"

  for city in topPlaces
    place = city.place
    [x, y] = env.projection [place.lon, place.lat]
    label = "#{place.name}: #{city.values}"
    metrics = context.measureText label
    # Why the hell not?  http://stackoverflow.com/a/1135363/26876
    metrics.height = context.measureText('m').width
    margin = 5
    padding = 10

    x += margin
    y += margin

    context.beginPath()
    context.rect x, y - metrics.height, metrics.width + padding, metrics.height + padding
    context.fillStyle = 'rgba(31, 192, 30, 0.7)'
    context.fill()

    context.beginPath()
    context.fillStyle = 'rgba(255, 255, 255, 1)'
    context.arc x - margin, y - margin, 2, 0, Math.PI * 2, false
    context.fill()

    context.beginPath()
    context.fillStyle = '#fff'
    context.fillText(label, x + padding / 2, y + padding / 2)
    context.fill()

$(document).on 'data.loaded', render
