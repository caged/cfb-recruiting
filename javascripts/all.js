(function() {
  var containerForLink, findLastPathSegment, handleClick, hideContainer, showContainer;

  handleClick = function(event) {
    var container, tab, tabContainer, _base, _i, _len, _ref;
    container = $(containerForLink(this));
    if (event.which === 2 || event.metaKey) {
      return true;
    }
    if (!container.length) {
      return true;
    }
    tabContainer = $(this).closest('.js-hard-tabs');
    _ref = tabContainer.find('a.selected');
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      tab = _ref[_i];
      $(tab).removeClass('selected');
      hideContainer(tabContainer, $(containerForLink(tab)));
    }
    showContainer(tabContainer, container);
    $(this).addClass('selected');
    if (typeof (_base = window.history).replaceState === "function") {
      _base.replaceState(null, document.title, $(this).attr('href'));
    }
    tabContainer.trigger('tabChanged', {
      link: $(this)
    });
    return false;
  };

  $(document).on('click', '.js-hard-tabs a', handleClick);

  $(document).on('click', '.js-secondary-hard-link', handleClick);

  containerForLink = function(link) {
    var id, pathSegment;
    pathSegment = findLastPathSegment($(link).attr('href'));
    id = $(link).attr('data-container-id') ? $(link).attr('data-container-id') : pathSegment;
    return document.getElementById(id);
  };

  hideContainer = function(container, target) {
    if (container.hasClass('js-large-data-tabs')) {
      if (target[0] === null) {
        return $();
      }
      if (target.is(':visible') && !target[0].style.width) {
        target.css({
          width: "" + (target.width()) + "px"
        });
      }
      return target.css({
        position: 'absolute',
        left: '-9999px'
      });
    } else {
      return target.hide();
    }
  };

  showContainer = function(container, target) {
    if (container.hasClass('js-large-data-tabs')) {
      if (target[0] === null) {
        return $();
      }
      if (!target.is(':visible')) {
        target.show();
      }
      return target.css({
        position: '',
        left: ''
      });
    } else {
      return target.show();
    }
  };

  findLastPathSegment = function(pathString) {
    var matches;
    if (pathString == null) {
      pathString = document.location.pathname;
    }
    pathString = pathString.replace(/\?.+|#.+/, '');
    matches = pathString.match(/[^\/]+\/?$/);
    if (matches.length === 0) {
      alert('Invalid tab link!');
    }
    return matches[0].replace('/', '');
  };

}).call(this);
(function() {
  var render;

  render = function(event, env) {
    var clearCountyInfo, drawCountyAtYear, drawRecruitPathsToSchool, drawStar, lineStringFromPlayerToSchool, map, recruit, school, selectedSchool, tip, updateCountyInfo, zoomGroup, _i, _j, _len, _len1, _ref, _ref1;
    if (d3.select('#county-map svg').node()) {
      return;
    }
    selectedSchool = null;
    tip = d3.tip().attr('class', 'd3-tip').html(function(d) {
      return ("<h3>" + d.team + "</h3>") + ("<p>" + d.city + "</p>");
    });
    map = d3.select('#county-map').append('svg').attr('width', env.width).attr('height', env.height).call(tip);
    zoomGroup = map.append('g');
    _ref = env.recruits;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      recruit = _ref[_i];
      recruit.coordinates = env.projection([recruit.lat, recruit.lon]);
    }
    _ref1 = env.schools;
    for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
      school = _ref1[_j];
      school.coordinates = env.projection([school.lat, school.lon]);
    }
    updateCountyInfo = function(county) {
      var container, el, props, stars;
      props = county.properties;
      container = d3.select('.js-county-info').style('display', 'block');
      el = container.append('div').attr('class', 'js-county').datum(props);
      el.append('span').attr('class', 'title').text(function(d) {
        return "" + (d.name.replace('County', '')) + " County";
      });
      if (props.male_18_24) {
        stars = el.append('ul').attr('class', 'star-recruits').selectAll('li').data(function(d) {
          var star, _k, _len2, _ref2;
          stars = [];
          _ref2 = ['five', 'four', 'three', 'two'];
          for (_k = 0, _len2 = _ref2.length; _k < _len2; _k++) {
            star = _ref2[_k];
            stars.push({
              label: star,
              count: d["" + star + "_star"]
            });
          }
          return stars;
        }).enter().append('li');
        stars.append('span').attr('class', function(d) {
          return "star " + d.label;
        }).html("&#9733;");
        stars.append('span').attr('class', 'count').text(function(d) {
          return d.count;
        });
        return el.append('span').attr('class', 'cam').html(function(d) {
          return "<span class='count'>" + (d3.format(',')(d.male_18_24)) + "</span>            males 18-24yo according to The U.S. Census Bureau.";
        });
      } else {
        return el.append('span').attr('class', 'no-recruits').html('No 2-5&#9733; recruits');
      }
    };
    clearCountyInfo = function(county) {
      d3.select('.js-county-info').style('display', 'none');
      return d3.select('.js-county').remove();
    };
    lineStringFromPlayerToSchool = function(player, school) {
      return {
        type: 'LineString',
        coordinates: [[parseFloat(school.lat), parseFloat(school.lon)], [parseFloat(player.lat), parseFloat(player.lon)]],
        properties: player
      };
    };
    drawStar = function(x, y, points, innerRadius, outerRadius) {
      var angle, currX, currY, i, r, results;
      results = "";
      angle = Math.PI / points;
      i = 0;
      while (i < 2 * points) {
        r = ((i & 1) === 0 ? outerRadius : innerRadius);
        currX = x + Math.cos(i * angle) * r;
        currY = y + Math.sin(i * angle) * r;
        if (i === 0) {
          results = "" + currX + "," + currY;
        } else {
          results += "," + currX + "," + currY;
        }
        i++;
      }
      return results;
    };
    drawRecruitPathsToSchool = function(school) {
      var connections, numRecruits, recruitFeatures, recruitNodes, schoolRecruits, year;
      school = school || selectedSchool;
      if (!school) {
        return;
      }
      year = $('.js-year').val();
      schoolRecruits = env.recruits.filter(function(r) {
        var fromSchool, _ref2;
        fromSchool = (_ref2 = r.institution) === school.team || _ref2 === school.alt;
        if (year) {
          return fromSchool && r.year === year;
        } else {
          return fromSchool;
        }
      });
      recruitFeatures = schoolRecruits.map(function(player) {
        return lineStringFromPlayerToSchool(player, school);
      });
      schoolRecruits.sort(function(a, b) {
        return d3.ascending(parseFloat(a.stars), parseFloat(b.stars));
      });
      recruitFeatures.sort(function(a, b) {
        return d3.ascending(parseFloat(a.properties.stars), parseFloat(b.properties.stars));
      });
      numRecruits = schoolRecruits.length;
      connections = zoomGroup.selectAll('.connection').data(recruitFeatures, function(d) {
        return "" + d.properties.name + ":" + d.properties.school;
      });
      connections.enter().append('path').attr('d', env.path).attr('class', function(d) {
        return "connection stars" + d.properties.stars;
      }).style('stroke', function(d) {
        return env.colors[d.properties.stars - 1];
      }).attr('stroke-dasharray', function() {
        var len;
        len = this.getTotalLength();
        return "" + len + "," + len;
      }).attr('stroke-dashoffset', function() {
        return this.getTotalLength();
      }).transition().duration(100).delay(function(d, i) {
        return i / numRecruits * 200;
      }).attr('stroke-dashoffset', 0);
      connections.exit().remove();
      recruitNodes = zoomGroup.selectAll('.recruit').data(schoolRecruits, function(d) {
        return d.id;
      });
      recruitNodes.enter().append('circle').attr('cx', function(d) {
        return d.coordinates[0];
      }).attr('cy', function(d) {
        return d.coordinates[1];
      }).attr('r', 0).style('fill', '#fff').attr('class', 'recruit').transition().delay(function(d, i) {
        return i / numRecruits * 200;
      }).duration(200).style('fill', function(d) {
        return env.colors[d.stars - 1];
      }).attr('r', 3);
      recruitNodes.exit().remove();
      selectedSchool = school;
      return map.on('click', function() {
        if (d3.event.target.tagName === 'svg') {
          connections.remove();
          return recruitNodes.remove();
        }
      });
    };
    env.fill.domain([
      0.2, d3.max(env.counties.features, function(d) {
        return d.properties.total;
      })
    ]);
    map.append('text').attr('class', 'ui-info').attr('x', env.width / 2).attr('y', 25).text('Select school to see recruit locations');
    zoomGroup.append('g').attr('class', 'counties').selectAll('path.county').data(env.counties.features).enter().append('path').attr('class', 'county').style('fill', function(d) {
      return env.fill(d.properties.total || 0);
    }).attr('d', env.path).on('mouseover', updateCountyInfo).on('mouseout', clearCountyInfo);
    zoomGroup.append('path').datum(env.states).attr('class', 'states').attr('d', env.path);
    zoomGroup.append('path').datum(env.nation).attr('class', 'nation').attr('d', env.path);
    zoomGroup.selectAll('.schools').data(env.schools).enter().append('polygon').attr('class', 'school').attr('points', function(d) {
      return drawStar(d.coordinates[0], d.coordinates[1], 5, 6, 3);
    }).on('mouseover', tip.show).on('mouseout', tip.hide).on('click', drawRecruitPathsToSchool);
    drawCountyAtYear = function(year) {
      var numCounties;
      year = year ? "total_" + year : 'total';
      numCounties = env.counties.features.length;
      env.fill.domain([
        0.2, d3.max(env.counties.features, function(d) {
          return d.properties[year];
        })
      ]);
      return zoomGroup.selectAll('.county').transition().delay(function(d, i) {
        return i / numCounties * 500;
      }).style('fill', function(d) {
        return env.fill(d.properties[year] || 0);
      }).style('stroke', function(d) {
        var stars;
        stars = d.properties[year] || 0;
        if (stars > 0) {
          return env.fill(stars || 0);
        } else {
          return '#333';
        }
      });
    };
    return $('.js-year').on('change', function() {
      var year;
      year = $(this).val();
      drawCountyAtYear(year);
      return drawRecruitPathsToSchool();
    });
  };

  $(document).on('data.loaded', render);

}).call(this);
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
(function() {
  var init;

  init = function() {
    var autoProjectTo, colors, e, fill, height, heightAdjust, path, projection, width, _i, _len, _ref;
    heightAdjust = 0;
    _ref = $('.no-height');
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      e = _ref[_i];
      heightAdjust += $(e).outerHeight();
    }
    width = $('#master-map-container').width();
    height = $(window).height() - heightAdjust - 40;
    projection = d3.geo.albersUsa().scale(1).translate([0, 0]);
    path = d3.geo.path().projection(projection);
    fill = d3.scale.log().clamp(true).range(['#111', '#00ff00']);
    colors = ['#a634f4', '#5adacc', '#bcf020', '#eeb016', '#ec180c'];
    d3.select('#master-map-container').style('height', "" + height + "px");
    autoProjectTo = function(geometry) {
      var b, s, t;
      projection.scale(1).translate([0, 0]);
      b = path.bounds(geometry);
      s = 1 / Math.max((b[1][0] - b[0][0]) / width, (b[1][1] - b[0][1]) / height);
      t = [(width - s * (b[1][0] + b[0][0])) / 2, (height - s * (b[1][1] + b[0][1])) / 2];
      return projection.scale(s).translate(t);
    };
    return $.when($.ajax('data/counties.json'), $.ajax('data/schools.csv'), $.ajax('data/recruits.csv'), $.ajax('data/places.csv')).then(function(r1, r2, r3, r4) {
      var count, counties, county, env, maxyear, nation, places, props, recruits, schools, states, usa, year, _j, _k, _len1, _ref1;
      $('.js-loading').hide();
      usa = r1[0];
      schools = d3.csv.parse(r2[0]);
      recruits = d3.csv.parse(r3[0]);
      places = d3.csv.parse(r4[0]);
      schools.sort(function(a, b) {
        return d3.ascending(parseFloat(a.capacity), parseFloat(b.capacity));
      });
      recruits = recruits.filter(function(d) {
        return +d.stars >= 2;
      });
      states = topojson.mesh(usa, usa.objects.states, function(a, b) {
        return a.id !== b.id;
      });
      counties = topojson.feature(usa, usa.objects.counties);
      nation = topojson.mesh(usa, usa.objects.nation);
      autoProjectTo(nation);
      maxyear = -Infinity;
      _ref1 = counties.features;
      for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
        county = _ref1[_j];
        props = county.properties;
        props.timeline = [];
        if (props.total) {
          props.total -= county.properties.one_star;
          for (year = _k = 2002; _k <= 2013; year = _k += 1) {
            count = props["total_" + year] || 0;
            if (count > maxyear) {
              maxyear = count;
            }
            props.timeline.push({
              year: year,
              count: count
            });
          }
        }
      }
      env = {
        states: states,
        counties: counties,
        nation: nation,
        schools: schools,
        recruits: recruits,
        places: places,
        projection: projection,
        path: path,
        fill: fill,
        colors: colors,
        width: width,
        height: height,
        maxyear: maxyear
      };
      $(document).trigger('data.loaded', env);
      return $('.js-hard-tabs').on('tabChanged', function(event, object) {
        var canvas;
        canvas = $('#recruit-map canvas');
        if (object.link.text() === 'Recruits' && +canvas.attr('width') === 0) {
          canvas.remove();
          return $(document).trigger('data.loaded', env);
        }
      });
    });
  };

  $(init);

}).call(this);
