# all.coffee

render = ->
  width       = $(document.body).width()
  height      = Math.min(500, width)
  colors      = ['#1a1a1a', '#353535', '#555', '#757575', '#959595', '#b5b5b5', '#d5d5d5', '#f5f5f5']
  color       = d3.scale.quantile().range colors
  projection  = d3.geo.albersUsa().scale(1).translate [ 0, 0 ]
  path        = d3.geo.path().projection(projection)

  map = d3.select('body').append('svg')
    .attr('width', width)
    .attr('height', height)

  d3.json '/data/recruiting.json', (usa) ->
  tip = d3.tip().attr('class', 'd3-tip').html (d) ->
    p = d.properties
    " <h3>#{p.name} County</h3>
      <p><strong>#{p.four_star || 0}</strong> &star;&star;&star;&star; athletes since 2002.</p>"
  map.call(tip)
    states   = topojson.mesh usa, usa.objects.states, (a, b) -> a.id != b.id
    counties = topojson.feature usa, usa.objects.counties
    nation   = topojson.mesh usa, usa.objects.nation

    projection.scale(1).translate([0, 0])
    b = path.bounds(nation)
    s = 1 / Math.max((b[1][0] - b[0][0]) / width, (b[1][1] - b[0][1]) / height)
    t = [(width - s * (b[1][0] + b[0][0])) / 2, (height - s * (b[1][1] + b[0][1])) / 2]
    projection.scale(s).translate(t)

    map.append('g')
      .attr('class', 'counties')
    .selectAll('path.county')
      .data(counties.features)
    .enter().append('path')
      .attr('d', path)
      .attr('class', 'county')
      .style('fill', (d) -> fill(parseFloat(d.properties.four_star)))
      .attr('d', path)
      .on('mouseover', tip.show)
      .on('mouseout', tip.hide)

    map.append('path')
      .datum(states)
      .attr('class', 'states')
      .attr('d', path)

    map.append('path')
      .datum(nation)
      .attr('class', 'nation')
      .attr('d', path)
    # map.append('g')
    #   .attr('class', 'nation')
    # .selectAll('path.nation')
    #   .data(nation)
    # .enter().append('path')
    #   .attr('d', path)
    #   .attr('class', 'nation')

  # svg.append("g")
  #     .attr("class", "counties")
  #   .selectAll("path")
  #     .data(topojson.feature(us, us.objects.counties).features)
  #   .enter().append("path")
  #     .attr("d", path)
  #     .style("fill", function(d) { return fill(path.area(d)); });

  # svg.append("path")
  #     .datum(topojson.mesh(us, us.objects.states, function(a, b) { return a.id !== b.id; }))
  #     .attr("class", "states")
  #     .attr("d", path);

    # Auto scale map to fit within bounds


$(render)
