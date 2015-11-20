-- Run via
-- psql -v the_year=2015 -f sql/out-of-state.sql recruiting
-- copy (
  select year,
         institution,
         sum(cast((i.state = r.region_a) as int)) as in_state,
         sum(cast((i.state != r.region_a) as int)) as out_state,
         count(*) as total
  from institutions i
  inner join recruits r on institution in (i.name,
                                           i.alt)
  where stars >= 4
  group by 1, 2
  order by 5 desc, 4 desc
-- ) to stdout with csv header;
