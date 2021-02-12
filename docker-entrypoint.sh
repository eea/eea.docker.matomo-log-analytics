#!/bin/sh

if [ -z "${MATOMO_URL}" ] || [ -z "${MATOMO_TOKEN}" ] ; then
  echo "Needs MATOMO_URL and MATOMO_TOKEN to work"
  exit 1
fi

MATOMO_RECORDERS=${MATOMO_RECORDERS:-4}
MATOMO_IMPORT_OPTIONS=${MATOMO_IMPORT_OPTIONS:-"--enable-http-errors --enable-http-redirects --enable-static --enable-bots"}

mkdir -p /analytics/logs/

if [ "$@" == "run" ]; then
   for dir in $( ls -d /analytics/logs/* ); do
	site_id=$(basename "$dir")
        echo "Found site id $site_id"
	find /analytics/logs/$site_id -type f -name "access_log.*" ! -iname "access_log.$(date -u  '+%Y-%m-%d-%H')*" > /tmp/list_files.txt	
        
        mkdir -p /analytics/processed/$site_id/	
	touch /analytics/processed/$site_id/log.$(date -u  '+%Y-%m')
        
	cat /analytics/processed/$site_id/log.* | grep /analytics/logs/$site_id > /tmp/list_processed
	
	for file in $(grep -Fvx -f /tmp/list_processed /tmp/list_files.txt); do
		result=$(python /import_logs.py   --token-auth=${MATOMO_TOKEN} --idsite=$site_id  --url=$MATOMO_URL --recorders=$MATOMO_RECORDERS $MATOMO_IMPORT_OPTIONS $file 2>&1 )
	        if [ $? -eq 0 ]; then
			number_processed=$(echo "$result"  | grep successfully | awk '{print $1}' )
                	echo "[Date]:$(date -u  '+%Y-%m-%d-%H-%M-%S') [Status]:OK [Records Imported]:$number_processed [File name]:" >> /analytics/processed/$site_id/log.$(date -u  '+%Y-%m')
                        echo "$file" >> /analytics/processed/$site_id/log.$(date -u  '+%Y-%m')
			echo "$file processed succesfully, with the following result:"
			echo "$result"
		else
			echo "IMPORT_LOG_ERROR - $file"
			echo "$result"
	        fi

                LOG_DATE=$(head -n 1 $file  | sed 's/^.* \[\([0-9A-Za-z\/:]*\) .*\] .*$/\1/g')
                LOG_DATE_MATOMO=$(python -c "
from datetime import datetime
print(datetime.strptime('${LOG_DATE}', '%d/%b/%Y:%H:%M:%S').strftime('%Y-%m-%d'))")  
		 
		#invalidate reports
		 echo "Invalidating date ${LOG_DATE_MATOMO} for site id ${site_id}"
                 curl -sS "${MATOMO_URL}?module=API&method=CoreAdminHome.invalidateArchivedReports&idSites=${site_id}&dates=${LOG_DATE_MATOMO}&token_auth=${MATOMO_TOKEN}"


	done	

        

       
        if [ -f /analytics/processed/$site_id/log.$(date -u -d "@$(( $(date +%s) - 86400 * 63 ))"  '+%Y-%m') ]; then
		rm -f  /analytics/processed/$site_id/log.$(date -u -d "@$(( $(date +%s) - 86400 * 63 ))"  '+%Y-%m') 
        fi

   done

else
	exec "$@"
fi
