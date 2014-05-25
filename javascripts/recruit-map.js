(function() {
  var render, scaleForRetina;

  scaleForRetina = function(canvas, context) {
    var backingStoreRatio, devicePixelRatio, ratio, rheight, rwidth;
    rwidth = $(canvas.node()).width();
    rheight = $(canvas.node()).width();
    devicePixelRatio = window.devicePixelRatio || 1;
    backingStoreRatio = context.webkitBackingStorePixelRatio || context.mozBackingStorePixelRatio || context.msBackingStorePixelRatio || context.oBackingStorePixelRatio || context.backingStorePixelRatio || 1;
    ratio = devicePixelRatio / backingStoreRatio;
    if (window.devicePixelRatio !== backingStoreRatio) {
      canvas.attr('width', rwidth * ratio).attr('height', rheight * ratio).style('width', rwidth + 'px').style('height', rheight + 'px');
      return context.scale(ratio, ratio);
    }
  };

  render = function(event, env) {
    var bygid, canvas, city, context, coordinates, hotspots, label, margin, metrics, padding, path, place, radius, recruit, topPlaces, x, y, _i, _j, _len, _len1, _ref, _ref1, _results;
    canvas = d3.select('#recruit-map').append('canvas').attr('width', env.width).attr('height', env.height);
    context = canvas.node().getContext('2d');
    path = d3.geo.path().projection(env.projection).context(context);
    radius = d3.scale.linear().domain([1, 2, 3, 4, 5]).range([0.1, 0.3, 0.5, 0.8, 2]);
    scaleForRetina(canvas, context);
    context.beginPath();
    path(env.nation);
    path(env.states);
    context.save();
    context.lineWidth = 1;
    context.strokeStyle = "#333";
    context.stroke();
    bygid = d3.nest().key(function(d) {
      return d.gid;
    }).rollup(function(d) {
      return d[0];
    }).map(env.places);
    hotspots = d3.nest().key(function(d) {
      return d.place_gid;
    }).rollup(function(d) {
      return d.length;
    }).entries(env.recruits);
    hotspots.sort(function(a, b) {
      return d3.descending(a.values, b.values);
    });
    topPlaces = hotspots.slice(0, 15).map(function(spot) {
      spot.place = bygid[spot.key];
      return spot;
    });
    _ref = env.recruits;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      recruit = _ref[_i];
      coordinates = env.projection([recruit.lat, recruit.lon]);
      context.beginPath();
      context.arc(coordinates[0], coordinates[1], radius(recruit.stars), 0, Math.PI * 2, false);
      context.fillStyle = 'rgba(255, 255, 255, 0.3)';
      context.shadowColor = 'rgba(255, 255, 255, 0.5)';
      context.fill();
    }
    context.restore();
    context.shadowBlur = 0;
    context.globalCompositeOperation = 'normal';
    context.fillStyle = 'fff';
    context.lineWidth = 0.5;
    context.strokeStyle = "333";
    context.font = "12px Helvetica Neue";
    _results = [];
    for (_j = 0, _len1 = topPlaces.length; _j < _len1; _j++) {
      city = topPlaces[_j];
      place = city.place;
      _ref1 = env.projection([place.lon, place.lat]), x = _ref1[0], y = _ref1[1];
      label = "" + place.name + ": " + city.values;
      metrics = context.measureText(label);
      metrics.height = context.measureText('m').width;
      margin = 5;
      padding = 10;
      x += margin;
      y += margin;
      context.beginPath();
      context.rect(x, y - metrics.height, metrics.width + padding, metrics.height + padding);
      context.fillStyle = 'rgba(31, 192, 30, 0.7)';
      context.fill();
      context.beginPath();
      context.fillStyle = 'rgba(255, 255, 255, 1)';
      context.arc(x - margin, y - margin, 2, 0, Math.PI * 2, false);
      context.fill();
      context.beginPath();
      context.fillStyle = '#fff';
      context.fillText(label, x + padding / 2, y + padding / 2);
      _results.push(context.fill());
    }
    return _results;
  };

  $(document).on('data.loaded', render);

}).call(this);
