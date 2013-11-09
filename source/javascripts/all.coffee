#= require tabs
#= require county-map
#= require recruit-map

init = ->
  heightAdjust = 0
  heightAdjust += $(e).outerHeight() for e in $('.no-height')
  width      = $('.map').width()
  height     = $(window).height() - heightAdjust - 40
  projection = d3.geo.albersUsa().scale(1).translate [ 0, 0 ]
  path       = d3.geo.path().projection projection
  fill       = d3.scale.log().clamp(true).range ['#111', '#00ff00']

  autoProjectTo = (geometry) ->
    projection.scale(1).translate([0, 0])
    b = path.bounds(geometry)
    s = 1 / Math.max((b[1][0] - b[0][0]) / width, (b[1][1] - b[0][1]) / height)
    t = [(width - s * (b[1][0] + b[0][0])) / 2, (height - s * (b[1][1] + b[0][1])) / 2]
    projection.scale(s).translate(t)

  $.when($.ajax('/data/counties.json'),
         $.ajax('/data/schools.csv'),
         $.ajax('/data/recruits.csv')).then (r1, r2, r3) ->

    usa      = r1[0]
    schools = d3.csv.parse r2[0]
    recruits = d3.csv.parse r3[0]

    schools.sort (a, b) -> d3.ascending parseFloat(a.capacity), parseFloat(b.capacity)

    # Convert to GeoJSON
    states   = topojson.mesh usa, usa.objects.states, (a, b) -> a.id != b.id
    counties = topojson.feature usa, usa.objects.counties
    nation   = topojson.mesh usa, usa.objects.nation

    autoProjectTo(nation)


$(init)
