#!/bin/bash

catalinaout=/opt/lesspaper/tomkat/logs
logfile=zabbix.log

while getopts "f:l:" opt; do
    case "$opt" in
    f)  if [ "$OPTARG" != "__NO__" ]
        then
            export catalinaout=$OPTARG
        fi
        ;;
    l)  if [ "$OPTARG" != "__NO__" ]
        then
            export logfile=$OPTARG
        fi
        ;;
    esac
done

# check if file date is today
filetime=$(stat -c %y $catalinaout/$logfile | cut -f1 -d' ')
curtime=$(date +"%Y-%m-%d")

if [ "$filetime" == "$curtime" ]
then
    cat $catalinaout/$logfile | gawk 'BEGIN { total=0 } { total+=$2} END { print total/NR/1000 }'
else
    echo 0
fi
