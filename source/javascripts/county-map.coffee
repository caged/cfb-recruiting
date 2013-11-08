render = (event, env) ->
  colors = ['#a634f4', '#5adacc', '#bcf020', '#eeb016', '#ec180c']

  map = d3.select('#county-map').append('svg')
    .attr('width', env.width)
    .attr('height', env.height)

  zoomGroup = map.append 'g'

  recruit.coordinates = env.projection [recruit.lat, recruit.lon] for recruit in env.recruits
  school.coordinates  = env.projection [school.lat, school.lon] for school in env.schools

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
    schoolRecruits  = env.recruits.filter((r) -> r.institution in [school.team, school.alt])
    recruitFeatures = schoolRecruits.map((player) -> lineStringFromPlayerToSchool(player, school))
    schoolRecruits.sort  (a, b) -> d3.ascending parseFloat(a.stars), parseFloat(b.stars)
    recruitFeatures.sort (a, b) -> d3.ascending parseFloat(a.properties.stars), parseFloat(b.properties.stars)
    numRecruits = schoolRecruits.length

    connections = zoomGroup
      .selectAll('.connection')
      .data(recruitFeatures, (d) -> "#{d.properties.name}:#{d.properties.school}")

    connections.enter().append('path')
      .attr('class', (d) -> "connection stars#{d.properties.stars}")
      .style('stroke', (d) -> colors[d.properties.stars - 1])
      .attr('d', env.path)

    connections.exit().remove()

    recruitNodes = zoomGroup.selectAll('.recruit')
      .data(schoolRecruits, (d) -> d.id)

    recruitNodes.enter().append('circle')
      .attr('cx', (d) -> d.coordinates[0])
      .attr('cy', (d) -> d.coordinates[1])
      .attr('r', 0)
      .style('fill', (d) -> colors[d.stars - 1])
      .attr('class', 'recruit')
    .transition()
      .delay((d, i) -> i / numRecruits * 300)
      .style('fill', '#fff')
      .attr('r', 6)
    .transition()
      .attr('r', 3)
      .ease('bounce')
      .style('fill', (d) -> colors[d.stars - 1])

    recruitNodes.exit().remove()

  # Set the fill domain based on the total number of recruits
  env.fill.domain [0.2, d3.max(env.counties.features, (d) -> d.properties.total)]

  # Add counties
  zoomGroup.append('g')
    .attr('class', 'counties')
  .selectAll('path.county')
    .data(env.counties.features)
  .enter().append('path')
    .attr('class', 'county')
    .style('fill', (d) -> env.fill(d.properties.total || 0))
    .attr('d', env.path)
    .style('stroke', (d) ->
      stars = d.properties.total || 0
      if stars > 0 then env.fill(stars || 0) else '#333')

  # Add states and nation
  zoomGroup.append('path').datum(env.states).attr('class', 'states').attr('d', env.path)
  zoomGroup.append('path').datum(env.nation).attr('class', 'nation').attr('d', env.path)

  zoomGroup.selectAll('.schools')
    .data(env.schools)
  .enter().append('circle')
    .attr('cx', (d) -> d.coordinates[0])
    .attr('cy', (d) -> d.coordinates[1])
    .attr('r', 4)
    .attr('class', 'school')
    .on('click', drawRecruitPathsToSchool)

$(document).on 'data.loaded', render
