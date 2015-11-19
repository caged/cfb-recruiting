

``` bash
# Add your Mapzen search API key here:
touch .env

# Fetch and geocode results
script/fetch-results
script/geocode-results
script/recruits2psql -d YOUR_DB_NAME
```
