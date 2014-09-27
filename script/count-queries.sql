-- dp0010005:   Male: 15 to 19 years
-- dp0010025:   Male: 20 to 24 years
-- dp0010026:   Male: 25 to 29 years

COPY (SELECT counties.geoid10 as geoid, counties.namelsad10 as name,
  SUM(CAST((stars = 5) AS INT)) as s5,
  SUM(CAST((stars = 4) AS INT)) as s4,
  SUM(CAST((stars = 3) AS INT)) as s3,
  SUM(CAST((stars = 2) AS INT)) as s2,
  SUM(CAST((stars = 1) AS INT)) as s1,
  SUM(CAST((recruits.year = 2015) AS INT)) as t2015,
  SUM(CAST((recruits.year = 2014) AS INT)) as t2014,
  SUM(CAST((recruits.year = 2013) AS INT)) as t2013,
  SUM(CAST((recruits.year = 2012) AS INT)) as t2012,
  SUM(CAST((recruits.year = 2011) AS INT)) as t2011,
  SUM(CAST((recruits.year = 2010) AS INT)) as t2010,
  SUM(CAST((recruits.year = 2009) AS INT)) as t2009,
  SUM(CAST((recruits.year = 2008) AS INT)) as t2008,
  SUM(CAST((recruits.year = 2007) AS INT)) as t2007,
  SUM(CAST((recruits.year = 2006) AS INT)) as t2006,
  SUM(CAST((recruits.year = 2005) AS INT)) as t2005,
  SUM(CAST((recruits.year = 2004) AS INT)) as t2004,
  SUM(CAST((recruits.year = 2003) AS INT)) as t2003,
  SUM(CAST((recruits.year = 2002) AS INT)) as t2002,
  COUNT(1) as total,
  (max(dp0010024) + max(dp0010025) + max(dp0010026)) as male_pop
FROM counties
INNER JOIN recruits ON st_contains(counties.geom, recruits.geom)
WHERE stars > 1
GROUP BY counties.namelsad10, counties.geoid10)
TO '/tmp/cfb-counties.csv' WITH CSV HEADER;
