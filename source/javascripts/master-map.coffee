render = ->
  width       = $('#master-map').width()
  height      = 1000
  projection  = d3.geo.albersUsa().scale(1).translate [ 0, 0 ]
  path        = d3.geo.path().projection(projection)
  fill        = d3.scale.log().clamp(true).range ['#111', '#00ff00']
  starCount   = 'total'
  zoomGroup   = null
  colors      = ['#a634f4', '#5adacc', '#bcf020', '#eeb016', '#ec180c']

  # Main objects
  recruits = null
  schools  = null
  counties = null
  states   = null

  tip = d3.tip().attr('class', 'd3-tip').offset([-10, 0]).html (d) ->
    if d.properties?
      p = d.properties
      name = if /county/i.test(p.name) then p.name else "#{p.name} County"
      "<h3>#{name}</h3><p><strong>#{p[starCount] || 0}</strong> athletes.</p>"
    else if d.weight?
      "<h3>#{d.stars} &#9733; #{d.name} - #{d.year}</h3><p>#{d.weight}lb #{d.position} from #{d.school} in #{d.location}"
    else
      "<h3>#{d.team}</h3><p>#{d.stadium} in #{d.city}, #{d.state}</p>"

  map = d3.select('#master-map').append('svg')
    .attr('width', width)
    .attr('height', height)
    .call(tip)

  # Generates a LineString GeoJSON object from a player to a school
  #
  # player - Object
  # school - Object
  #
  # Returns a GeoJSON LineString object
  lineStringFromPlayerToSchool = (player, school) ->
    type: 'LineString'
    coordinates: [[school.lat, school.lon], [player.lat, player.lon]]
    properties: player

  # Draw Great Arcs to recruit locations from the school.
  #
  # Find all recruits that have committed to the current school
  # and draw a path from the recruit back to the school.
  #
  # school - Object
  #
  # Returns nothing
  drawRecruitPathsToSchool = (school) ->
    schoolRecruits = recruits.filter((r) -> r.institution in [school.team, school.alt])
    schoolRecruits.sort (a, b) -> d3.ascending(parseFloat(a.stars), parseFloat(b.stars))

    recruitFeatures = schoolRecruits.map((player) -> lineStringFromPlayerToSchool(player, school))
    recruitFeatures.sort (a, b) -> d3.ascending(parseFloat(a.properties.stars), parseFloat(b.properties.stars))

    connections = zoomGroup
      .selectAll('.connection')
      .data(recruitFeatures, (d) -> "#{d.properties.name}:#{d.properties.school}")

    connections.enter().append('path')
      .attr('class', (d) -> "connection stars#{d.properties.stars}")
      .attr('d', path)
      .style('stroke', (d) -> colors[d.properties.stars - 1])

    connections.exit().remove()

    recruitNodes = zoomGroup.selectAll('.recruit')
      .data(schoolRecruits, (d) -> "#{d.name}:#{d.school}")

    recruitNodes.enter().append('circle')
      .attr('cx', (d) -> d.coordinates[0])
      .attr('cy', (d) -> d.coordinates[1])
      .attr('r', 4)
      .style('fill', (d) -> colors[d.stars - 1])
      .attr('class', 'recruit')
      .on('mouseover', tip.show)
      .on('mouseout', tip.hide)

    recruitNodes.exit().remove()

  # Draw the base map
  #
  # r1 - Nation, State and County polygons
  # r2 - Schools
  # r3 - Recruits
  #
  # Returns nothing
  drawMap = (r1, r2, r3) ->
    usa      = r1[0]
    schools = d3.csv.parse r2[0]
    recruits = d3.csv.parse r3[0]

    schools.sort (a, b) -> d3.ascending parseFloat(a.capacity), parseFloat(b.capacity)

    # Convert to GeoJSON
    states   = topojson.mesh usa, usa.objects.states, (a, b) -> a.id != b.id
    counties = topojson.feature usa, usa.objects.counties
    nation   = topojson.mesh usa, usa.objects.nation

    # Set the fill domain based on the total number of recruits
    fill.domain [0.2, d3.max(counties.features, (d) -> d.properties[starCount])]

    # Auto scale map based on bounds
    projection.scale(1).translate([0, 0])
    b = path.bounds(nation)
    s = 1 / Math.max((b[1][0] - b[0][0]) / width, (b[1][1] - b[0][1]) / height)
    t = [(width - s * (b[1][0] + b[0][0])) / 2, (height - s * (b[1][1] + b[0][1])) / 2]
    projection.scale(s).translate(t)

    for recruit in recruits
      recruit.coordinates = projection [recruit.lat, recruit.lon]

    for school in schools
      school.position = projection [school.lat, school.lon]

    zoomGroup = map.append('g')

    # Add counties
    zoomGroup.append('g')
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
        if stars > 0 then fill(stars || 0) else '#333')

    # Add states and nation
    zoomGroup.append('path').datum(states).attr('class', 'states').attr('d', path)
    zoomGroup.append('path').datum(nation).attr('class', 'nation').attr('d', path)

    zoomGroup.selectAll('.schools')
      .data(schools)
    .enter().append('rect')
      .attr('x', (d) -> d.position[0])
      .attr('y', (d) -> d.position[1])
      .attr('width', 7)
      .attr('height', 7)
      .attr('class', 'school')
      .classed('gt', (d) -> d.name == 'Georgia Tech')
      .on('mouseover', tip.show)
      .on('mouseout', tip.hide)
      .on('click', drawRecruitPathsToSchool)

  $.when($.ajax('/data/counties.json'),
         $.ajax('/data/schools.csv'),
         $.ajax('/data/recruits.csv')).then(drawMap)

$(render)
