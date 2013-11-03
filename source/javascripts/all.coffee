# all.coffee

render = ->
  width       = $(document.body).width()
  height      = width
  projection  = d3.geo.albersUsa().scale(1).translate [ 0, 0 ]
  path        = d3.geo.path().projection(projection)
  fill        = d3.scale.log().clamp(true).range ['#f1f1f1', '#0aafed']

  map = d3.select('body').append('svg')
    .attr('width', width)
    .attr('height', height)

  tip = d3.tip().attr('class', 'd3-tip').html (d) ->
    if d.properties?
      p = d.properties
      "<h3>#{p.name} County</h3><p><strong>#{p.four_star || 0}</strong> &star;&star;&star;&star; athletes since 2002.</p>"
    else
      "<h3>#{d.team}</h3><p>#{d.stadium} in #{d.city}, #{d.state}</p>"

  #tip2 = d3.tip().attr('class', 'd3-tip').h

  map.call(tip)

  $.when($.ajax('/data/recruiting.json'), $.ajax('/data/stadiums.csv')).then (r1, r2) ->
    usa      = r1[0]
    stadiums = d3.csv.parse(r2[0])

    # Convert to GeoJSON
    states   = topojson.mesh usa, usa.objects.states, (a, b) -> a.id != b.id
    counties = topojson.feature usa, usa.objects.counties
    nation   = topojson.mesh usa, usa.objects.nation


    fill.domain [0.1, d3.max(counties.features, (d) -> d.properties.four_star)]

    # Auto scale map based on bounds
    projection.scale(1).translate([0, 0])
    b = path.bounds(nation)
    s = 1 / Math.max((b[1][0] - b[0][0]) / width, (b[1][1] - b[0][1]) / height)
    t = [(width - s * (b[1][0] + b[0][0])) / 2, (height - s * (b[1][1] + b[0][1])) / 2]
    projection.scale(s).translate(t)

    # Add counties
    map.append('g')
      .attr('class', 'counties')
    .selectAll('path.county')
      .data(counties.features)
    .enter().append('path')
      .attr('class', 'county')
      .style('fill', (d) -> fill(d.properties.four_star || 0))
      .attr('d', path)
      .on('mouseover', tip.show)
      .on('mouseout', tip.hide)

    # Add states mesh
    map.append('path')
      .datum(states)
      .attr('class', 'states')
      .attr('d', path)

    # Add nation mesh
    map.append('path')
      .datum(nation)
      .attr('class', 'nation')
      .attr('d', path)

    for stadium in stadiums
      stadium.position = projection [stadium.lat, stadium.lon]

    map.selectAll('.stadiums')
      .data(stadiums)
    .enter().append('circle')
      .attr('cx', (d) -> d.position[0])
      .attr('cy', (d) -> d.position[1])
      .attr('r', 3)
      .attr('class', 'stadium')
      .on('mouseover', tip.show)
      .on('mouseout', tip.hide)


$(render)
