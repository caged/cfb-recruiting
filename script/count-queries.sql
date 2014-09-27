-- SELECT cfb_counties.name, count(1) AS total FROM cfb_counties
-- INNER JOIN recruits ON st_contains(cfb_counties.geom, recruits.geom)
-- WHERE stars='5'
-- GROUP BY cfb_counties.gid

-- h76007:      Male: 18 and 19 years
-- h76008:      Male: 20 years
-- h76009:      Male: 21 years
-- h76010:      Male: 22 to 24 years
-- h76011:      Male: 25 to 29 years

COPY (SELECT counties.geoid10, counties.namelsad10,
  SUM(CAST((stars = 5) AS INT)) as five_star,
  SUM(CAST((stars = 4) AS INT)) as four_star,
  SUM(CAST((stars = 3) AS INT)) as three_star,
  SUM(CAST((stars = 2) AS INT)) as two_star,
  SUM(CAST((stars = 1) AS INT)) as one_star,
  SUM(CAST((recruits.year = 2015) AS INT)) as total_2015,
  SUM(CAST((recruits.year = 2014) AS INT)) as total_2014,
  SUM(CAST((recruits.year = 2013) AS INT)) as total_2013,
  SUM(CAST((recruits.year = 2012) AS INT)) as total_2012,
  SUM(CAST((recruits.year = 2011) AS INT)) as total_2011,
  SUM(CAST((recruits.year = 2010) AS INT)) as total_2010,
  SUM(CAST((recruits.year = 2009) AS INT)) as total_2009,
  SUM(CAST((recruits.year = 2008) AS INT)) as total_2008,
  SUM(CAST((recruits.year = 2007) AS INT)) as total_2007,
  SUM(CAST((recruits.year = 2006) AS INT)) as total_2006,
  SUM(CAST((recruits.year = 2005) AS INT)) as total_2005,
  SUM(CAST((recruits.year = 2004) AS INT)) as total_2004,
  SUM(CAST((recruits.year = 2003) AS INT)) as total_2003,
  SUM(CAST((recruits.year = 2002) AS INT)) as total_2002,
  COUNT(1) as total,
  (max(dp0010024) + max(dp0010025) + max(dp0010026)) as male_15_29
FROM counties
INNER JOIN recruits ON st_contains(counties.geom, recruits.geom)
WHERE stars > 1
GROUP BY counties.namelsad10, counties.geoid10)
TO '/tmp/cfb-counties.csv' WITH CSV HEADER;

-- SELECT (SELECT cfb_counties.name, count(1) AS total FROM cfb_counties
-- INNER JOIN recruits ON st_contains(cfb_counties.geom, recruits.geom)
-- WHERE stars='5'
-- GROUP BY cfb_counties.gid) as counts;
