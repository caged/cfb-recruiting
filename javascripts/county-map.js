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
        return "" + d.name + " Totals";
      });
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
        return "<span class='count'>" + (d3.format(',')(d.male_18_24)) + "</span>          males 18-24yo according to The U.S. Census Bureau.";
      });
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
      return selectedSchool = school;
    };
    env.fill.domain([
      0.2, d3.max(env.counties.features, function(d) {
        return d.properties.total;
      })
    ]);
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
