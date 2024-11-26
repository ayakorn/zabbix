#!/bin/bash

catalinaout=/opt/lesspaper/tomkat/logs
logfile=zabbix.log

while getopts "f:" opt; do
    case "$opt" in
    f)  if [ "$OPTARG" != "__NO__" ]
        then
            export catalinaout=$OPTARG
        fi
        ;;
    esac
done

# check if file date is today
filetime=$(stat -c %y $catalinaout/$logfile | cut -f1 -d' ')
curtime=$(date +"%Y-%m-%d")

if [ "$filetime" == "$curtime" ]
then
    sort -k2 -rn $catalinaout/$logfile | head -10 | gawk 'BEGIN { total=0 } { total+=$2} END { print total/NR/1000 }'
else
    echo 0
fi
