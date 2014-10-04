select
  count(*),
  places.name,
  states.state,
  recruits.school,
  ((count(*) / 14.0) / (max(dp0010024) + max(dp0010025) + max(dp0010026))) * 10000 as power_index
from recruits
inner join places on places.geoid = recruits.place_geoid
inner join places_demographics on places_demographics.geoid10 = places.geoid
inner join states on states.state_fips = places.statefp
group by 2,3,4
having count(*) > 10
order by 5 desc
