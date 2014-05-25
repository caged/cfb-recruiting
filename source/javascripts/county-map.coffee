render = (event, env) ->
  selectedSchool = null

  tip = d3.tip().attr('class', 'd3-tip')
      .html (d) ->
        "<h3>#{d.team}</h3>" +
        "<p>#{d.city}</p>"

  map = d3.select('#county-map').append('svg')
    .attr('width', env.width)
    .attr('height', env.height)
    .call(tip)

  zoomGroup = map.append 'g'

  recruit.coordinates = env.projection [recruit.lat, recruit.lon] for recruit in env.recruits
  school.coordinates  = env.projection [school.lat, school.lon] for school in env.schools

  # Update county information dialog with information about the focused county
  #
  # county - Object
  #
  # Returns nothing
  updateCountyInfo = (county) ->
    props = county.properties
    container = d3.select '.js-county-info'
    margin = top: 20, left: 40, bottom: 0, right: 0
    vwidth = parseFloat(container.style 'width') - margin.left - margin.right
    vheight = 225 - margin.top - margin.bottom

    props.timeline.forEach (p) ->
      p.percent = ((p.count / props.male_18_24) * 100).toFixed(2)

    vy = d3.scale.ordinal().domain(props.timeline.map (p) -> p.year).rangeBands [vheight, 0], 0.1
    vx = d3.scale.linear().domain([0, env.maxyear]).range [0, vwidth]

    yax = d3.svg.axis().scale(vy).orient('left')
    xax = d3.svg.axis()
      .scale(vx)
      .orient('top')
      .ticks(4)
      .tickSize(vheight)

    el = container.append('div')
      .attr('class', 'js-county')
      .datum(props)

    el.append('span')
      .attr('class', 'title')
      .text((d) -> d.name)

    stars = el.append('ul')
      .attr('class', 'star-recruits')
    .selectAll('li')
      .data((d) ->
          stars = []
          for star in ['five', 'four', 'three', 'two']
            stars.push label: star, count: d["#{star}_star"]
          stars)
    .enter().append('li')

    stars.append('span')
      .attr('class', (d) -> "star #{d.label}")
      .html("&#9733;")

    stars.append('span')
      .attr('class', 'count')
      .text((d) -> d.count)

    el.append('span')
      .attr('class', 'cam')
      .html((d) ->
        "<span class='count'>#{d3.format(',')(d.male_18_24)}</span>
          males 18-24yo according to The U.S. Census Bureau."
      )

    vis = el.append('svg')
      .attr('width', vwidth + margin.left + margin.right)
      .attr('height', vheight + margin.top + margin.bottom)
    .append('g')
      .attr('transform', "translate(#{margin.left}, #{margin.top})")

    vis.append('g')
      .attr('class', 'y axis')
      .call(yax)

    vis.append('g')
      .attr('transform', "translate(0, #{vheight})")
      .attr('class', 'x axis')
      .call(xax)

    grect = vis.selectAll('.county-bar')
      .data((d) -> d.timeline)
    .enter().append('g')
      .attr('class', 'county-bar')
      .attr('transform', (d, i) -> "translate(0, #{vy d.year})")

    grect.append('rect')
      .attr('height', vy.rangeBand())
      .attr('width', (d) -> vx(d.count))

  clearCountyInfo = (county) ->
    d3.select('.js-county').remove()

  # Generates a LineString GeoJSON object from a player to a school
  #
  # player - Object
  # school - Object
  #
  # Returns a GeoJSON LineString object
  lineStringFromPlayerToSchool = (player, school) ->
    type: 'LineString'
    coordinates: [[parseFloat(school.lat), parseFloat(school.lon)], [parseFloat(player.lat), parseFloat(player.lon)]]
    properties: player

  # Draw a star polygon
  #
  # x - center x
  # y - center y
  # points - number of star points
  # innerRadius - radius inside the start
  # outerRadius - radius outside the star
  #
  # Returns a point string for a polygon
  drawStar = (x, y, points, innerRadius, outerRadius) ->
    results = ""
    angle = Math.PI / points
    i = 0

    while i < 2 * points
      r = (if (i & 1) is 0 then outerRadius else innerRadius)
      currX = x + Math.cos(i * angle) * r
      currY = y + Math.sin(i * angle) * r
      if i is 0
        results = "#{currX},#{currY}"
      else
        results += ",#{currX},#{currY}"
      i++
    results


  # Draw Great Arcs to recruit locations from the school.
  #
  # Find all recruits that have committed to the current school
  # and draw a path from the recruit back to the school.
  #
  # school - Object
  #
  # Returns nothing
  drawRecruitPathsToSchool = (school) ->
    school = school || selectedSchool
    return if !school

    year = $('.js-year').val()
    schoolRecruits  = env.recruits.filter (r) ->
      fromSchool = r.institution in [school.team, school.alt]
      if year then (fromSchool and r.year == year) else fromSchool

    recruitFeatures = schoolRecruits.map((player) -> lineStringFromPlayerToSchool(player, school))
    schoolRecruits.sort  (a, b) -> d3.ascending parseFloat(a.stars), parseFloat(b.stars)
    recruitFeatures.sort (a, b) -> d3.ascending parseFloat(a.properties.stars), parseFloat(b.properties.stars)
    numRecruits = schoolRecruits.length

    connections = zoomGroup
      .selectAll('.connection')
      .data(recruitFeatures, (d) -> "#{d.properties.name}:#{d.properties.school}")

    connections.enter().append('path')
      .attr('d', env.path)
      .attr('class', (d) -> "connection stars#{d.properties.stars}")
      .style('stroke', (d) -> env.colors[d.properties.stars - 1])
      .attr('stroke-dasharray', -> len = @getTotalLength(); "#{len},#{len}")
      .attr('stroke-dashoffset', -> @getTotalLength())
    .transition()
      .duration(100)
      .delay((d, i) -> i / numRecruits * 200)
      .attr('stroke-dashoffset', 0)


    connections.exit().remove()

    recruitNodes = zoomGroup.selectAll('.recruit')
      .data(schoolRecruits, (d) -> d.id)

    recruitNodes.enter().append('circle')
      .attr('cx', (d) -> d.coordinates[0])
      .attr('cy', (d) -> d.coordinates[1])
      .attr('r', 0)
      .style('fill', '#fff')
      .attr('class', 'recruit')
    .transition()
      .delay((d, i) -> i / numRecruits * 200)
      .duration(200)
      .style('fill', (d) -> env.colors[d.stars - 1])
      .attr('r', 3)

    recruitNodes.exit().remove()
    selectedSchool = school

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
    .on('mouseover', updateCountyInfo)
    .on('mouseout', clearCountyInfo)
    .style('stroke', (d) ->
      stars = d.properties.total || 0
      if stars > 0 then env.fill(stars || 0) else '#333')

  # Add states and nation
  zoomGroup.append('path').datum(env.states).attr('class', 'states').attr('d', env.path)
  zoomGroup.append('path').datum(env.nation).attr('class', 'nation').attr('d', env.path)

  zoomGroup.selectAll('.schools')
    .data(env.schools)
  .enter().append('polygon')
    .attr('class', 'school')
    .attr('points', (d) -> drawStar(d.coordinates[0], d.coordinates[1], 5, 6, 3))
    .on('mouseover', tip.show)
    .on('mouseout', tip.hide)
    .on('click', drawRecruitPathsToSchool)

  # Shade the county by the selected year
  drawCountyAtYear = (year) ->
    year = if year then "total_#{year}" else 'total'
    numCounties = env.counties.features.length

    env.fill.domain [0.2, d3.max(env.counties.features, (d) -> d.properties[year])]

    zoomGroup.selectAll('.county')
      .transition()
      .delay((d, i) -> i / numCounties * 500)
      .style('fill', (d) -> env.fill(d.properties[year] || 0))
      .style('stroke', (d) ->
        stars = d.properties[year] || 0
        if stars > 0 then env.fill(stars || 0) else '#333')

  $('.js-year').on 'change', ->
    year = $(this).val()
    drawCountyAtYear year
    drawRecruitPathsToSchool()

$(document).on 'data.loaded', render
