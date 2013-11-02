-- SELECT cfb_counties.name, count(1) AS total FROM cfb_counties
-- INNER JOIN recruits ON st_contains(cfb_counties.geom, recruits.geom)
-- WHERE stars='5'
-- GROUP BY cfb_counties.gid

SELECT cfb_counties.name,
  SUM(CAST((stars = 5) AS INT)) as five_star,
  SUM(CAST((stars = 4) AS INT)) as four_star,
  SUM(CAST((stars = 3) AS INT)) as three_star,
  SUM(CAST((stars = 2) AS INT)) as two_star,
  SUM(CAST((stars = 1) AS INT)) as one_star
FROM cfb_counties
INNER JOIN recruits ON st_contains(cfb_counties.geom, recruits.geom)
GROUP BY cfb_counties.name;

-- SELECT (SELECT cfb_counties.name, count(1) AS total FROM cfb_counties
-- INNER JOIN recruits ON st_contains(cfb_counties.geom, recruits.geom)
-- WHERE stars='5'
-- GROUP BY cfb_counties.gid) as counts;
