-- SELECT cfb_counties.name, count(1) AS total FROM cfb_counties
-- INNER JOIN recruits ON st_contains(cfb_counties.geom, recruits.geom)
-- WHERE stars='5'
-- GROUP BY cfb_counties.gid

-- h76007:      Male: 18 and 19 years
-- h76008:      Male: 20 years
-- h76009:      Male: 21 years
-- h76010:      Male: 22 to 24 years
-- h76011:      Male: 25 to 29 years

COPY (SELECT cfb_counties.geoid, cfb_counties.gisjoin, cfb_counties.name,
  SUM(CAST((stars = 5) AS INT)) as five_star,
  SUM(CAST((stars = 4) AS INT)) as four_star,
  SUM(CAST((stars = 3) AS INT)) as three_star,
  SUM(CAST((stars = 2) AS INT)) as two_star,
  SUM(CAST((stars = 1) AS INT)) as one_star,
  (max(h76007) + max(h76008) + max(h76009) + max(h76010)) as male_18_24
FROM cfb_counties
INNER JOIN recruits ON st_contains(cfb_counties.geom, recruits.geom)
LEFT JOIN cfb_counties_data on cfb_counties.gisjoin = cfb_counties_data.gisjoin
GROUP BY cfb_counties.name, cfb_counties.gisjoin, cfb_counties.geoid)
TO '/tmp/cfb-counties.csv' WITH CSV HEADER;

-- SELECT (SELECT cfb_counties.name, count(1) AS total FROM cfb_counties
-- INNER JOIN recruits ON st_contains(cfb_counties.geom, recruits.geom)
-- WHERE stars='5'
-- GROUP BY cfb_counties.gid) as counts;
