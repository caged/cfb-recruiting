#= require master-map
render = ->
  width       = $(document.body).width()
  height      = width
  projection  = d3.geo.albersUsa().scale(1).translate [ 0, 0 ]
  path        = d3.geo.path().projection(projection)
  fill        = d3.scale.log().clamp(true).range ['#111', '#ff00ff']
  starCount   = 'three_star'
  centered    = null
  geometries  = null
  colors      = ['#a634f4', '#f1f42f', '#bcf020', '#eeb016', '#ec180c']

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
      name = if /county/i.test(p.name) then p.name else "#{p.name} County"
      "<h3>#{name}</h3><p><strong>#{p[starCount] || 0}</strong> &star;&star;&star;&star; athletes since 2002.</p>"
    else if d.weight?
      "<h3>#{d.stars} &star; #{d.name} - #{d.year}</h3><p>#{d.weight}lb #{d.position} from #{d.school} in #{d.location}"
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
    geometries.append('g')
      .attr('class', 'counties')
    .selectAll('path.county')
      .data(counties.features)
    .enter().append('path')
      .attr('class', 'county')
      .style('fill', (d) -> fill(d.properties[starCount] || 0))
      .attr('d', path)
      .on('mouseover', tip.show)
      .on('mouseout', tip.hide)
      .style('stroke', (d) ->
        stars = d.properties[starCount] || 0
        if stars > 0 then fill(stars) else '#333')

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

    # recgroup = geometries.append('g')
    #   .attr('class', 'recruits')

    # recs = recgroup.selectAll('circle.recruit')
    #   .data(recruits)
    # .enter().append('circle')
    #   .attr('cx', (d) -> d.position[0])
    #   .attr('cy', (d) -> d.position[1])
    #   .attr('r', 1)
    #   .style('fill', '#ff00ff')
    #   .style('fill-opacity', 0)
    #   .attr('class', (d) -> d.school.toLowerCase().replace(' ', '-'))

# svg.append("path")
#     .datum({type: "LineString", coordinates: [[-77.05, 38.91], [116.35, 39.91]]})
#     .attr("class", "arc")
#     .attr("d", path)

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
      .on('click', (d) ->
        players = recruits.filter (r) -> r.institution in [d.team, d.alt] # && r.year == "2013"
        features = players.map (p) ->
          type: "LineString"
          coordinates: [[d.lat, d.lon], [p.lat, p.lon]]
          properties: p

        connections = map.selectAll('.connection')
          .data(features, (d) -> "#{d.properties.name}:#{d.properties.school}")

        connections.enter().append('path')
          .attr('class', 'connection')
          .attr('d', path)
          .style('stroke', (d) -> colors[d.properties.stars - 1])

        connections.exit().remove()

        recs = map.selectAll('.recruit')
          .data(players, (d) -> "#{d.name}:#{d.school}")

        recs.enter().append('circle')
          .attr('cx', (d) -> d.position[0])
          .attr('cy', (d) -> d.position[1])
          .attr('r', 2)
          .style('fill', (d) -> console.log d.stars; colors[d.stars - 1])
          .attr('class', 'recruit')

        recs.exit().remove()

      )

$(render)
