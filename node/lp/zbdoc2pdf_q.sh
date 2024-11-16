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

tmpdat=/var/tmp/zblp_doc2pdf_queue.$(date +"%d").dat

if [ -f $tmpdat ]
then
    comm -13 $tmpdat $catalinaout/$logfile | head -1 | cut -f3 -d' '
else
    echo 0
fi

cp $catalinaout/$logfile $tmpdat
