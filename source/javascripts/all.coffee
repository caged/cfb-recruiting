# all.coffee

render = ->
  width       = $(document.body).width()
  height      = width
  projection  = d3.geo.albersUsa().scale(1).translate [ 0, 0 ]
  path        = d3.geo.path().projection(projection)
  fill        = d3.scale.log().clamp(true).range ['#111', '#ff00ff']
  starCount   = 'three_star'
  centered    = null
  geometries  = null

  map = d3.select('body').append('svg')
    .attr('width', width)
    .attr('height', height)

  map.append('defs').append('filter')
    .attr('id', 'blend')
  .append('feBlend')
    .attr('mode', 'screen')
    .attr('in1', 'BackgroundImage')

  tip = d3.tip().attr('class', 'd3-tip').html (d) ->
    if d.properties?
      p = d.properties
      "<h3>#{p.name} County</h3><p><strong>#{p[starCount] || 0}</strong> &star;&star;&star;&star; athletes since 2002.</p>"
    else
      "<h3>#{d.team}</h3><p>#{d.stadium} in #{d.city}, #{d.state}</p>"

  map.call(tip)

  onCountyClick = (d) ->
    if d && centered != d
      [x,y] = path.centroid(d)
      centered = d
      k = 4
    else
      x = width / 2
      y = height / 2
      centered = null
      k = 1

    geometries.selectAll('path')
      .classed('active', centered && ((d) -> d == centered))

    translate = " translate(#{width / 2},#{height / 2})
        scale(#{k})
        translate({#{-x},#{-y})"

    geometries.transition()
      .duration(750)
      .attr('transform', "
        translate(#{width / 2},#{height / 2})
        scale(#{k})
        translate(#{-x},#{-y})")
      .style('stroke-width', "#{1.5 / k}px")

  $.when($.ajax('/data/counties.json'),
         $.ajax('/data/stadiums.csv'),
         $.ajax('/data/recruits.csv')).then (r1, r2, r3) ->

    usa      = r1[0]
    stadiums = d3.csv.parse(r2[0])
    recruits = d3.csv.parse(r3[0])

    # Convert to GeoJSON
    states   = topojson.mesh usa, usa.objects.states, (a, b) -> a.id != b.id
    counties = topojson.feature usa, usa.objects.counties
    nation   = topojson.mesh usa, usa.objects.nation


    fill.domain [0.1, d3.max(counties.features, (d) -> d.properties[starCount])]

    # Auto scale map based on bounds
    projection.scale(1).translate([0, 0])
    b = path.bounds(nation)
    s = 1 / Math.max((b[1][0] - b[0][0]) / width, (b[1][1] - b[0][1]) / height)
    t = [(width - s * (b[1][0] + b[0][0])) / 2, (height - s * (b[1][1] + b[0][1])) / 2]
    projection.scale(s).translate(t)

    geometries = map.append('g')

    # Add counties
    # geometries.append('g')
    #   .attr('class', 'counties')
    # .selectAll('path.county')
    #   .data(counties.features)
    # .enter().append('path')
    #   .attr('class', 'county')
    #   .style('fill', (d) -> fill(d.properties[starCount] || 0))
    #   .attr('d', path)
    #   .on('mouseover', tip.show)
    #   .on('mouseout', tip.hide)
    #   .on('click', onCountyClick)
    #   .style('stroke', (d) ->
    #     stars = d.properties[starCount] || 0
    #     if stars > 0 then fill(stars) else '#333'
    #   )

    # Add states mesh
    geometries.append('path')
      .datum(states)
      .attr('class', 'states')
      .attr('d', path)

    # Add nation mesh
    geometries.append('path')
      .datum(nation)
      .attr('class', 'nation')
      .attr('d', path)

    for recruit in recruits
      recruit.position = projection [recruit.lat, recruit.lon]

    recs = geometries.append('g')
      .attr('class', 'recruits')

    recs.selectAll('circle.recruit')
      .data(recruits)
    .enter().append('circle')
      .attr('cx', (d) -> d.position[0])
      .attr('cy', (d) -> d.position[1])
      .attr('r', 1)
      .style('fill', '#ff00ff')
      # .attr('filter', 'url(#blend)')

    for stadium in stadiums
      stadium.position = projection [stadium.lat, stadium.lon]

    geometries.selectAll('.stadiums')
      .data(stadiums)
    .enter().append('circle')
      .attr('cx', (d) -> d.position[0])
      .attr('cy', (d) -> d.position[1])
      .attr('r', 3)
      .attr('class', 'stadium')
      .on('mouseover', tip.show)
      .on('mouseout', tip.hide)
$(render)
