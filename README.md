
# Matomo log analytics importer docker 

https://github.com/matomo-org/matomo-log-analytics/



## Usage

docker run -it  --name test -e MATOMO_URL=http://xxxxxx/ -e MATOMO_USERNAME=test -e MATOMO_PASSWORD=test --rm  -v $(pwd)/logs:/analytics eeacms/matomo-log-analytics


### Volume/local directory structure example ( SITE_ID = 4)
logs/
logs/logs
logs/logs/4
logs/logs/4/access_log.2018-10-03-17
logs/logs/4/access_log.2018-10-04-12
logs/logs/4/access_log.2018-10-04-13

### Result file format example:
cat logs/processed/4/log.2018-10
2018-10-04-17-08-40 /analytics/logs/4/access_log.2018-10-03-17 OK 1
2018-10-04-17-08-42 /analytics/logs/4/access_log.2018-10-04-12 OK 51
2018-10-04-17-08-44 /analytics/logs/4/access_log.2018-10-04-13 OK 51


