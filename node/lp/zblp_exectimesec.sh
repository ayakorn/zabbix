#!/bin/bash

catalinaout=/opt/lesspaper/tomcat/logs

while getopts "f:" opt; do
    case "$opt" in
    f)  if [ "$OPTARG" != "__NO__" ]
        then
            export catalinaout=$OPTARG
        fi
        ;;
    esac
done

cat $catalinaout/exectime.log | /bin/grep "^$(date +'%d %b %Y')" | /bin/grep -o 'executionTime=.* ms' | /usr/bin/awk -F'[= ]' 'BEGIN { exectime = 0 } { exectime = exectime+$2 } END { printf "%d", exectime/1000 }' 

