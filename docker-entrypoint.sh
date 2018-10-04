#!/bin/sh

if [ -z "${MATOMO_URL}" ] || [ -z "${MATOMO_USERNAME}" ] || [ -z "${MATOMO_PASSWORD}" ] ; then
  echo "Needs MATOMO_URL, MATOMO_USERNAME and MATOMO_PASSWORD to work"
  exit 1
fi

mkdir -p /analytics/logs/

if [ "$@" == "run" ]; then
   for dir in $( ls -d /analytics/logs/* ); do
	site_id=$(basename "$dir")
        echo "Found site id $site_id"
	find /analytics/logs/$site_id -type f -name "access_log.*" ! -iname "access_log.$(date -u  '+%Y-%m-%d-%H')*" > /tmp/list_files.txt	
        
        mkdir -p /analytics/processed/$site_id/	
	touch /analytics/processed/$site_id/log.$(date -u  '+%Y-%m')
        
	grep -Fx -f /analytics/processed/$site_id/log.$(date -u  '+%Y-%m') /tmp/list_files.txt

	for file in $(grep -Fxv -f /analytics/processed/$site_id/log.$(date -u  '+%Y-%m') /tmp/list_files.txt); do
		result=$(python /import_logs.py   --login=${MATOMO_USERNAME} --password=${MATOMO_PASSWORD} --idsite=$site_id  --url=$MATOMO_URL --recorders=1 --enable-http-errors --enable-http-redirects --enable-static $file 2>&1 )
	        if [ $? -eq 0 ]; then
			number_processed=$(echo "$result"  | grep successfully | awk '{print $1}' )
                	echo "$(date -u  '+%Y-%m-%d-%H-%M-%S') $file OK $number_processed" >> /analytics/processed/$site_id/log.$(date -u  '+%Y-%m')
                        echo "$file processed succesfully"
			echo "$result"
		else
			echo "IMPORT_LOG_ERROR - $file"
			echo "$result"
	        fi

	done	
       
        if [ -f /analytics/processed/$site_id/log.$(date -u -d "@$(( $(date +%s) - 86400 * 63 ))"  '+%Y-%m') ]; then
		rm -f  /analytics/processed/$site_id/log.$(date -u -d "@$(( $(date +%s) - 86400 * 63 ))"  '+%Y-%m') 
        fi

   done

else
	exec "$@"
fi
