#!/bin/sh

if [ -z "${MATOMO_URL}" ] || [ -z "${MATOMO_TOKEN}" ] ; then
  echo "Needs MATOMO_URL and MATOMO_TOKEN to work"
  exit 1
fi

MATOMO_RECORDERS=${MATOMO_RECORDERS:-4}
MATOMO_IMPORT_OPTIONS=${MATOMO_IMPORT_OPTIONS:-"--enable-http-errors --enable-http-redirects --enable-static --enable-bots"}
MATOMO_MAX_REQUESTS_PERS=${MATOMO_MAX_REQUESTS_PERS:-1000}

mkdir -p /analytics/logs/

if [ "$@" == "run" ]; then
   for dir in $( ls -d /analytics/logs/* ); do
      site_id=$(basename "$dir")
      echo "Found site id $site_id"
      find /analytics/logs/$site_id -type f -name "access_log.*" ! -iname "access_log.$(date -u  '+%Y-%m-%d-%H')*" > /tmp/list_files.txt
        
      mkdir -p /analytics/processed/$site_id/    
      touch /analytics/processed/$site_id/log.$(date -u  '+%Y-%m')
      touch /analytics/processed/$site_id/invalidate
        
      cat /analytics/processed/$site_id/log.* | grep /analytics/logs/$site_id > /tmp/list_processed
    
      for file in $(grep -Fvx -f /tmp/list_processed /tmp/list_files.txt); do
        echo "Starting to run on $file"
        result=$(python /import_logs.py   --token-auth=${MATOMO_TOKEN} --idsite=$site_id  --url=$MATOMO_URL --recorders=$MATOMO_RECORDERS $MATOMO_IMPORT_OPTIONS $file 2>&1 )
        import_exit_code=$?
        requests_pers=$(echo "$result"  |grep "Requests imported per second" | awk '{print $5}')
        requests_pers_check=$(echo "$result"  |grep "Requests imported per second" | awk -v max="$MATOMO_MAX_REQUESTS_PERS" '{ if (max<$5) print "FAIL"}')

        if [ $import_exit_code -eq 0 ] && [ $(echo $result | grep "Logs import summary" | wc -l ) -gt 0 ] && [ $(echo $result | grep "^ *0 requests imported successfully" | wc -l) -eq 0 ] && [ -z "$requests_pers_check" ]; then
            number_processed=$(echo "$result"  | grep successfully | awk '{print $1}' )
            total_time=$(echo "$result"  | grep "Total time" | awk '{print $3}' )
            echo "[Date]:$(date -u  '+%Y-%m-%d-%H-%M-%S') [Status]:OK [Records Imported]:$number_processed [Duration (seconds)]:$total_time [Requests per s]:$requests_pers [File name]:" >> /analytics/processed/$site_id/log.$(date -u  '+%Y-%m')
            echo "$file" >> /analytics/processed/$site_id/log.$(date -u  '+%Y-%m')
            echo "$file processed succesfully, with the following result:"
            echo "$result"
            LOG_DATE=$(head -n 1 $file  | sed 's/^.* \[\([0-9A-Za-z\/:]*\) .*\] .*$/\1/g')
            LOG_DATE_MATOMO=$(python -c "
from datetime import datetime
print(datetime.strptime('${LOG_DATE}', '%d/%b/%Y:%H:%M:%S').strftime('%Y-%m-%d'))")  
         
            echo "${LOG_DATE}" >> /analytics/processed/$site_id/invalidate
        else
               if [ -n "$requests_pers_check" ]; then
                   echo "Too many requests per second - $requests_pers > $MATOMO_MAX_REQUESTS_PERS, will not mark the file as imported successfully"
                   echo "IMPORT_LOG_ERROR_CHECK - $file"
               else    
                   echo "IMPORT_LOG_ERROR - $file"
               fi
               echo "$result"
            fi

       done    

       current_hour=$(date +%H)
       current_day=$(date -u  '+%Y-%m-%d')  
       
       cat /analytics/processed/$site_id/invalidate | sort | uniq > /tmp/sorted
       mv /tmp/sorted /analytics/processed/$site_id/invalidate
       
       echo "----------------------------------------------"
       echo "Dates to invalidate during the night:"
       cat /analytics/processed/$site_id/invalidate
       echo "----------------------------------------------"
       
       if [ $current_hour -ge 1 ] && [ $current_hour -lt 7 ]; then
           for to_do in $(cat /analytics/processed/$site_id/invalidate); do
               if [[ ! "$to_do" == "$current_day" ]]; then
                    #invalidate reports
                    echo "Invalidating date ${to_do} for site id ${site_id}"
                    curl -sS "${MATOMO_URL}?module=API&method=CoreAdminHome.invalidateArchivedReports&idSites=${site_id}&dates=${to_do}&token_auth=${MATOMO_TOKEN}"
                    sed -i "/$to_do/d" /analytics/processed/$site_id/invalidate
               fi
           done
       fi
       
        if [ -f /analytics/processed/$site_id/log.$(date -u -d "@$(( $(date +%s) - 86400 * 63 ))"  '+%Y-%m') ]; then
            rm -f  /analytics/processed/$site_id/log.$(date -u -d "@$(( $(date +%s) - 86400 * 63 ))"  '+%Y-%m') 
        fi

   done

else
    exec "$@"
fi
