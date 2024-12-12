#!/bin/bash

catalinaout=/opt/lesspaper/tomkat/logs
logfile=doc2pdf.log

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
    cat $catalinaout/$logfile | grep ERROR | wc -l 
else
    echo 0
fi
