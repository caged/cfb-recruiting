(function() {
  var render;

  render = function(event, env) {
    var anchor, arc, clearCountyInfo, drawCountyAtYear, drawRecruitPathsToSchool, drawStar, left, lineStringFromPlayerToSchool, map, recruit, reset, school, selectedSchool, tip, tip2, top, updateCountyInfo, zoom, zoomGroup, zoomed, _i, _j, _len, _len1, _ref, _ref1, _ref2;
    if (d3.select('#county-map svg').node()) {
      return;
    }
    selectedSchool = null;
    tip = d3.tip().attr('class', 'd3-tip').html(function(d) {
      return "<span class='name'>" + d.team + "</span> -        <span>" + d.city + ", " + d.state + "</span>";
    });
    tip2 = d3.tip().attr('class', 'd3-tip-recruit').html(function(d) {
      return "<span class='name'>" + d.name + "</span>:        <span class='star" + d.stars + "'>" + d.stars + "&#9733;</span> " + d.weight + "lb        " + (d.position.toUpperCase()) + " recruit from <span>" + d.location + "</span>        in " + d.year;
    });
    arc = function(d) {
      var dr, dx, dy, source, target;
      source = d[0], target = d[1];
      dx = target[0] - source[0];
      dy = target[1] - source[1];
      dr = Math.sqrt(dx * dx + dy * dy);
      return "M" + source[0] + "," + source[1] + "A" + dr + "," + dr + " 0 0,1 " + target[0] + "," + target[1];
    };
    map = d3.select('#county-map').append('svg').attr('width', env.width).attr('height', env.height).call(tip).call(tip2);
    zoomGroup = map.append('g');
    zoomed = function() {
      zoomGroup.selectAll('.counties').style('stroke-width', 0.5 / d3.event.scale + 'px');
      zoomGroup.selectAll('.states').style('stroke-width', 0.5 / d3.event.scale + 'px');
      return zoomGroup.attr('transform', "translate(" + d3.event.translate + ")scale(" + d3.event.scale + ")");
    };
    reset = function() {
      return zoomGroup.transition().duration(750).call(zoom.translate([0, 0]).scale(1).event);
    };
    zoom = d3.behavior.zoom().translate([0, 0]).scale(1).scaleExtent([1, 8]).on("zoom", zoomed);
    zoomGroup.call(zoom).call(zoom.event);
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
        el.append('span').attr('class', 'cam').html(function(d) {
          return "<span class='count'>" + (d3.format(',')(d.male_18_24)) + "</span>            males 18-24yo according to The U.S. Census Bureau.";
        });
        return el.append('span').attr('class', 'note').text('Recruit numbers based on 2002-2013 combined totals.\
               Demographics from 2008-12 5 year American Community Survey.');
      } else {
        return el.append('span').attr('class', 'no-recruits').html('No 2-5&#9733; recruits');
      }
    };
    clearCountyInfo = function(county) {
      d3.select('.js-county-info').style('display', 'none');
      return d3.select('.js-county').remove();
    };
    lineStringFromPlayerToSchool = function(player, school) {
      player.points = [env.projection([school.lat, school.lon]), env.projection([player.lat, player.lon])];
      return player;
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
        return d3.ascending(parseFloat(a.stars), parseFloat(b.stars));
      });
      numRecruits = schoolRecruits.length;
      connections = zoomGroup.selectAll('.connection').data(recruitFeatures, function(d) {
        return "" + d.name + ":" + d.school;
      });
      connections.enter().append('path').attr('d', function(d) {
        return arc(d.points);
      }).attr('class', function(d) {
        return "connection stars" + d.stars;
      }).style('stroke', function(d) {
        console.log(d);
        return env.colors[d.stars - 1];
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
      }).attr('r', 0).style('fill', '#fff').attr('class', 'recruit').on('mouseover', tip2.show).on('mouseout', tip2.hide).transition().delay(function(d, i) {
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
    }).attr('d', env.path).on('mouseover', updateCountyInfo).on('mouseout', clearCountyInfo).on('click', reset);
    zoomGroup.append('path').datum(env.states).attr('class', 'states').attr('d', env.path);
    zoomGroup.append('path').datum(env.nation).attr('class', 'nation').attr('d', env.path);
    zoomGroup.selectAll('.schools').data(env.schools).enter().append('polygon').attr('class', function(d) {
      return "school " + (d.team.toLowerCase().replace(/\s+/, '-'));
    }).attr('points', function(d) {
      return drawStar(d.coordinates[0], d.coordinates[1], 5, 6, 3);
    }).on('mouseover', tip.show).on('mouseout', tip.hide).on('click', drawRecruitPathsToSchool);
    anchor = zoomGroup.select('.syracuse').datum();
    _ref2 = env.projection([+anchor.lat, +anchor.lon]), left = _ref2[0], top = _ref2[1];
    top = Math.max(top - 200, parseFloat(d3.select('header.no-height').style('height')) + 10);
    d3.select('.js-spurrier').style({
      display: 'block',
      top: "" + top + "px",
      left: "" + (left - 200) + "px"
    });
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
