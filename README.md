
# Matomo log analytics importer docker 

https://github.com/matomo-org/matomo-log-analytics/

## Environment variables

* *MATOMO_URL* - mandatory, the url that will be accessed to be able to send the tracking requests
* *MATOMO_TOKEN* - mandatory, superuser access token
* *MATOMO_RECORDERS* - default 4, the number of threads that will process the requests
* *MATOMO_IMPORT_OPTIONS* - default "--enable-http-errors --enable-http-redirects --enable-static --enable-bots", Matomo import options - referenced in https://matomo.org/docs/log-analytics-tool-how-to/
* *MATOMO_MAX_REQUESTS_PERS* - default 1000, will not mark file as processed if number of requests per second is bigger than it

## Usage

docker run -it  --name test -e MATOMO_URL=http://xxxxxx/ -e MATOMO_USERNAME=test -e MATOMO_PASSWORD=test --rm  -v $(pwd)/logs:/analytics eeacms/matomo-log-analytics


### Volume/local directory structure example ( SITE_ID = 4 & SITE_ID = 11 )

    /analytics/logs/
    /analytics/logs/4
    /analytics/logs/4/apache-logs/
    /analytics/logs/4/apache-logs/host1/
    /analytics/logs/4/apache-logs/host1/*
    /analytics/logs/4/apache-logs/host2/
    /analytics/logs/4/apache-logs/host2/*
    /analytics/logs/11
    /analytics/logs/11/logs/
    /analytics/logs/11/logs/*

