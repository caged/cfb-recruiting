#= require tabs
#= require county-map
#= require recruit-map

init = ->
  heightAdjust = 0
  heightAdjust += $(e).outerHeight() for e in $('.no-height')
  width      = $('#master-map-container').width()
  height     = $(window).height() - heightAdjust - 40
  projection = d3.geo.albersUsa().scale(1).translate [ 0, 0 ]
  path       = d3.geo.path().projection projection
  fill       = d3.scale.log().clamp(true).range ['#111', '#00ff00']
  colors     = ['#a634f4', '#5adacc', '#bcf020', '#eeb016', '#ec180c']

  d3.select('#master-map-container').style('height', "#{height}px")

  autoProjectTo = (geometry) ->
    projection.scale(1).translate([0, 0])
    b = path.bounds(geometry)
    s = 1 / Math.max((b[1][0] - b[0][0]) / width, (b[1][1] - b[0][1]) / height)
    t = [(width - s * (b[1][0] + b[0][0])) / 2, (height - s * (b[1][1] + b[0][1])) / 2]
    projection.scale(s).translate(t)

  $.when($.ajax('data/counties.json'),
         $.ajax('data/schools.csv'),
         $.ajax('data/recruits.csv'),
         $.ajax('data/places.csv')).then (r1, r2, r3, r4) ->

    $('.js-loading').hide()

    usa       = r1[0]
    schools   = d3.csv.parse r2[0]
    recruits  = d3.csv.parse r3[0]
    places    = d3.csv.parse r4[0]

    schools.sort (a, b) -> d3.ascending parseFloat(a.capacity), parseFloat(b.capacity)
    recruits = recruits.filter (d) -> +d.stars >= 2

    # Convert to GeoJSON
    states   = topojson.mesh usa, usa.objects.states, (a, b) -> a.id != b.id
    counties = topojson.feature usa, usa.objects.counties
    nation   = topojson.mesh usa, usa.objects.nation

    autoProjectTo(nation)

    # Create a timeline array from the recruits over the years and remove
    # one-star recruits from the total count because we're not that interested
    # in one-star recruits and it's highly likely that we don't have all of the
    # one star recruits in the database.
    maxyear = -Infinity
    for county in counties.features
      props = county.properties
      props.timeline = []
      if props.total
        props.total -= county.properties.one_star
        for year in [2002..2013] by 1
          count = props["total_#{year}"]
          maxyear = count if count > maxyear
          props.timeline.push {year, count}

    env = {states, counties, nation, schools, recruits, places, projection, path, fill, colors, width, height, maxyear}
    $(document).trigger 'data.loaded', env

    $('.js-hard-tabs').on 'tabChanged', (event, object) ->
      canvas = $ '#recruit-map canvas'
      if object.link.text() is 'Recruits' and +canvas.attr('width') is 0
        canvas.remove()
        $(document).trigger 'data.loaded', env

$(init)
