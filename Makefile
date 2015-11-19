data/gz/places.zip:
	mkdir -p $(dir $@)
	curl -L --remote-time 'http://www2.census.gov/geo/tiger/TIGER_DP/2013ACS/ACS_2013_5YR_PLACE.gdb.zip' -o $@.download
	mv $@.download $@

data/gdb/places.gdb: data/gz/places.zip
	mkdir -p $(dir $@)
	tar -xzm -C $(dir $@) -f $<
	mv data/gdb/ACS_2013_5YR_PLACE.gdb $@
